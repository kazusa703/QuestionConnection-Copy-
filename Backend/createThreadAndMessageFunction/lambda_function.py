# lambda_function.py for createThreadAndMessageFunction
import json
import boto3
import uuid
import datetime
import hashlib
import os
from botocore.exceptions import ClientError
from decimal import Decimal

# --- JSONエンコーダー (変更なし) ---
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return int(o) if o % 1 == 0 else float(o)
        return super(DecimalEncoder, self).default(o)

# --- クライアントとテーブルのセットアップ (修正) ---
dynamodb = boto3.resource('dynamodb')
# sns_client はこのLambdaでは不要になるため削除（またはコメントアウト）
# sns_client = boto3.client('sns') 
lambda_client = boto3.client('lambda') # (★ 追加) Lambdaクライアント

USERS_TABLE_NAME = os.environ.get('USERS_TABLE_NAME', 'Users')
THREADS_TABLE_NAME = os.environ.get('THREADS_TABLE_NAME', 'Threads')
MESSAGES_TABLE_NAME = os.environ.get('MESSAGES_TABLE_NAME', 'Messages')
# SNS_PLATFORM_ARN はこのLambdaでは不要
# SNS_PLATFORM_ARN = os.environ.get('SNS_PLATFORM_APPLICATION_ARN') 

# (★ 追加) 通知Lambdaの名前を環境変数から取得
PUBLISH_LAMBDA_NAME = os.environ['PUBLISH_LAMBDA_NAME'] 

users_table = dynamodb.Table(USERS_TABLE_NAME)
threads_table = dynamodb.Table(THREADS_TABLE_NAME)
messages_table = dynamodb.Table(MESSAGES_TABLE_NAME)


# --- (★ 削除) ---
# 既存の send_push_notification ヘルパー関数は丸ごと削除します
# def send_push_notification(recipient_id, sender_nickname, message_text, thread_id):
#     ... (このブロック全体を削除) ...


# --- ★★★ メインハンドラ (修正済み) ★★★ ---
def lambda_handler(event, context):
    try:
        print(f"Received event: {json.dumps(event)}")

        if 'body' not in event or not event['body']:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Request body is missing'})}
            
        dm_payload = json.loads(event['body'])
        
        sender_id = dm_payload.get('senderId')
        recipient_id = dm_payload.get('recipientId')
        
        if not sender_id or not recipient_id:
            return {'statusCode': 400, 'body': json.dumps({'error': 'senderId and recipientId are required'})}
        
        # (Cognito認証チェック - 変更なし)
        try:
            authenticated_user_id = event['requestContext']['authorizer']['claims']['sub']
            if sender_id != authenticated_user_id:
                return {'statusCode': 403, 'body': json.dumps({'error': 'Forbidden: Sender ID does not match authenticated user.'})}
        except KeyError:
            print("Warning: Could not verify authenticated user. Check Cognito Authorizer setup.")

        # スレッドIDを決定 (変更なし)
        sorted_ids = sorted([sender_id, recipient_id])
        thread_id_str = "".join(sorted_ids)
        thread_id = hashlib.md5(thread_id_str.encode()).hexdigest()

        timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S") + "Z"
        
        # 1. スレッド情報の取得と作成 (変更なし)
        thread_response = threads_table.get_item(Key={'threadId': thread_id})
        
        thread_item_to_return = None
        if 'Item' not in thread_response:
            thread_item = {
                'threadId': thread_id,
                'participants': sorted_ids,
                'questionTitle': dm_payload.get('questionTitle', ''),
                'lastUpdated': timestamp
            }
            threads_table.put_item(Item=thread_item)
            thread_item_to_return = thread_item
            print(f"New thread created: {thread_id}")
        else:
            thread_item_to_return = thread_response['Item']
        
        # 2. メッセージの書き込み (変更なし)
        message_item = {
            'threadId': thread_id,
            'timestamp': timestamp,
            'messageId': str(uuid.uuid4()),
            'senderId': sender_id,
            'text': dm_payload.get('messageText', '')
        }
        messages_table.put_item(Item=message_item)
        print(f"Message stored in thread: {thread_id}")
        
        # 3. スレッドの最終更新日を更新 (変更なし)
        threads_table.update_item(
            Key={'threadId': thread_id},
            UpdateExpression="SET lastUpdated = :t",
            ExpressionAttributeValues={':t': timestamp}
        )
        thread_item_to_return['lastUpdated'] = timestamp 
        print("Thread lastUpdated updated.")

        # --- ★★★ 4. プッシュ通知の「トリガー」処理 (ここを修正) ★★★ ---
        try:
            # 4a. 送信者のニックネームを取得 (これは再利用)
            sender_profile = users_table.get_item(
                Key={'userId': sender_id},
                ProjectionExpression="nickname"
            )
            sender_nickname = sender_profile.get('Item', {}).get('nickname', '（未設定）')

            # 4b. (★ 修正) Publish Lambda を非同期で呼び出す
            
            message_excerpt = dm_payload.get('messageText', '')
            
            # Publish Lambda に渡すペイロード
            publish_payload = {
                'recipientUserId': recipient_id,
                'type': 'DM',
                'threadId': thread_id,
                'senderName': sender_nickname,
                'messageExcerpt': message_excerpt
            }

            print(f"{recipient_id} への通知Lambdaをトリガーします")
            
            lambda_client.invoke(
                FunctionName=PUBLISH_LAMBDA_NAME,
                InvocationType='Event', # 非同期呼び出し。結果を待たない。
                Payload=json.dumps(publish_payload)
            )
            print(f"Publish Lambda ({PUBLISH_LAMBDA_NAME}) を正常に呼び出しました")
            
        except Exception as notify_error:
            # ★ 通知の「呼び出し失敗」がDM送信の成功を妨げないようにする
            print(f"WARNING: Publish Lambda invocation failed, but DM was saved. Error: {notify_error}")
        
        # --- 5. 成功レスポンス (変更なし) ---
        return {
            'statusCode': 201, # 200/201
            'headers': { 'Content-Type': 'application/json' },
            'body': json.dumps(thread_item_to_return, cls=DecimalEncoder)
        }
        
    except ClientError as e:
        error_message = f"DynamoDB Error: {e.response['Error']['Message']}"
        print(error_message)
        return {'statusCode': 500, 'body': json.dumps({'error': error_message})}
    except Exception as e:
        error_message = f"Message send processing failed. Error: {e}"
        print(error_message)
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
