# lambda_function.py for registerDeviceTokenFunction
import json
import boto3
import os
import re
from botocore.exceptions import ClientError
from decimal import Decimal
# uuidは不要なため削除

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return int(o) if o % 1 == 0 else float(o)
        return super(DecimalEncoder, self).default(o)

dynamodb = boto3.resource('dynamodb')
sns_client = boto3.client('sns')

# 環境変数から取得
USERS_TABLE_NAME = os.environ.get('USERS_TABLE_NAME', 'Users')
DEVICES_TABLE_NAME = os.environ.get('DEVICES_TABLE_NAME', 'Devices') 
SNS_PLATFORM_APPLICATION_ARN = os.environ.get('SNS_PLATFORM_APPLICATION_ARN') 

users_table = dynamodb.Table(USERS_TABLE_NAME)
devices_table = dynamodb.Table(DEVICES_TABLE_NAME) 

ARN_EXTRACT_REGEX = re.compile(r"(arn:aws:sns:[^ ]+)")

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}") 

    try:
        path_params = event.get('pathParameters')
        if not path_params or 'userId' not in path_params:
            raise ValueError("Missing 'userId' in path parameters")
        user_id = path_params['userId']
        
        try:
            authenticated_user_id = event['requestContext']['authorizer']['claims']['sub']
            if user_id != authenticated_user_id:
                print(f"Forbidden: Authenticated user {authenticated_user_id} cannot register token for {user_id}")
                return {'statusCode': 403, 'body': json.dumps({'error': 'Forbidden'})}
        except KeyError:
            print("Warning: Could not verify authenticated user. Check Cognito Authorizer setup.")

        if not event.get('body'):
            raise ValueError("Missing request body")
        body = json.loads(event.get('body'))
        if 'deviceToken' not in body:
            raise ValueError("Missing 'deviceToken' (raw token string) in request body")
        device_token_string = body['deviceToken'] 

        if not SNS_PLATFORM_APPLICATION_ARN:
            print("Error: SNS_PLATFORM_APPLICATION_ARN environment variable is not set")
            raise Exception("SNS_PLATFORM_APPLICATION_ARN environment variable is not set")
            
        if not DEVICES_TABLE_NAME:
            print("Error: DEVICES_TABLE_NAME environment variable is not set")
            raise Exception("DEVICES_TABLE_NAME environment variable is not set")

        print(f"Registering device for user: {user_id}, token: {device_token_string[:10]}...")

        endpoint_arn = None 
        try:
            # 1. 新規作成を試みる
            response = sns_client.create_platform_endpoint(
                PlatformApplicationArn=SNS_PLATFORM_APPLICATION_ARN,
                Token=device_token_string,
                CustomUserData=json.dumps({'userId': user_id}) 
            )
            endpoint_arn = response['EndpointArn']
            print(f"Successfully created SNS Platform Endpoint. ARN: {endpoint_arn}")

        except ClientError as e:
            error_msg = e.response['Error']['Message']
            print(f"SNS ClientError: {error_msg}")
            
            # 2. 'already exists' を含むかで判定
            if 'already exists' in error_msg:
                print("Endpoint or Token already exists. Extracting ARN and updating attributes...")
                
                try:
                    match = ARN_EXTRACT_REGEX.search(error_msg)
                    if not match:
                        print("Could not parse ARN from error message. Aborting.")
                        raise Exception(f"Could not parse ARN from error: {error_msg}")
                    
                    endpoint_arn = match.group(1)
                    print(f"Extracted ARN: {endpoint_arn}")
                    
                    print(f"Setting/Updating attributes for existing EndpointArn: {endpoint_arn}")
                    sns_client.set_endpoint_attributes(
                        EndpointArn=endpoint_arn,
                        Attributes={
                            'Token': device_token_string, 
                            'Enabled': 'true', 
                            'CustomUserData': json.dumps({'userId': user_id})
                        }
                    )
                    print("Existing endpoint attributes updated successfully.")
                    
                except Exception as update_err:
                    print(f"Failed to update existing endpoint attributes: {update_err}")
                    if "AuthorizationError" in str(update_err):
                         print("AuthorizationError on SetEndpointAttributes. Proceeding with extracted ARN.")
                    elif not endpoint_arn:
                         raise update_err 
                    else:
                         print("Proceeding with extracted ARN despite attribute update failure.")
            
            else:
                raise e 

        if not endpoint_arn:
             raise Exception("Failed to create or retrieve EndpointARN.")

        # ★★★ 3. Devicesテーブルを更新 (deviceId を rawToken に) ★★★
        print(f"Updating Devices table for userId: {user_id} with EndpointARN.")
        
        # 3a. DynamoDBのソートキー(SK)として 'rawToken' (device_token_string) を使用
        
        devices_table.put_item(
            Item={
                'userId': user_id,               # パーティションキー (PK)
                'deviceId': device_token_string, # ★ ソートキー (SK) として rawToken を使用
                'endpointArn': endpoint_arn,     # 通知送信に使うARN
                'rawToken': device_token_string  # (rawTokenはSKとしても保存)
            }
        )
        print(f"Devices table updated successfully with deviceId (rawToken): {device_token_string[:10]}...")


        # 4. 成功レスポン (200 OK)
        return {
            'statusCode': 200, 
            'headers': { 'Content-Type': 'application/json' },
            'body': json.dumps({'message': 'Device token registered successfully.'}, cls=DecimalEncoder)
        }

    except ClientError as e:
        print(f"CRITICAL ERROR (ClientError): {e.response['Error']['Message']}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
    except ValueError as ve: 
        print(f"CRITICAL ERROR (ValueError): {ve}")
        return {'statusCode': 400, 'body': json.dumps({'error': str(ve)})}
    except Exception as e: 
        print(f"CRITICAL ERROR (Exception): {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
