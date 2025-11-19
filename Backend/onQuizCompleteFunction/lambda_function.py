# lambda_function.py for onQuizCompleteFunction
import json
import boto3
import os
from botocore.exceptions import ClientError
from decimal import Decimal
import logging # ★ ロギングをインポート

# --- ロガーの設定 ---
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# --- JSONエンコーダー ---
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return int(o) if o % 1 == 0 else float(o)
        return super(DecimalEncoder, self).default(o)

# --- DynamoDBとSNSのセットアップ ---
dynamodb = boto3.resource('dynamodb')
sns_client = boto3.client('sns')

# --- 環境変数の取得 ---
try:
    QUESTIONS_TABLE_NAME = os.environ['QUESTIONS_TABLE_NAME']
    USERS_TABLE_NAME = os.environ['USERS_TABLE_NAME']
    # ★ 1. DEVICES_TABLE_NAME を読み込む
    DEVICES_TABLE_NAME = os.environ['DEVICES_TABLE_NAME'] 
except KeyError as e:
    logger.error(f"環境変数が設定されていません: {e}")
    raise Exception(f"環境変数の設定エラー: {e}")

questions_table = dynamodb.Table(QUESTIONS_TABLE_NAME)
users_table = dynamodb.Table(USERS_TABLE_NAME)
# ★ 2. devices_table を初期化
devices_table = dynamodb.Table(DEVICES_TABLE_NAME)

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # 1. パラメータの取得
        body = json.loads(event.get('body', '{}'))
        score = body.get('score')
        total_questions = body.get('totalQuestions')
        question_id = event.get('pathParameters', {}).get('questionId')
        solver_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub')

        if not all([score is not None, total_questions is not None, question_id, solver_id]):
            raise ValueError("Missing required parameters (score, totalQuestions, questionId, or solverId)")

        # 2. 全問正解かチェック
        if score != total_questions:
            logger.info(f"Not a perfect score ({score}/{total_questions}). No notification sent.")
            return {'statusCode': 200, 'body': json.dumps({'message': 'Not a perfect score, no notification sent.'})}

        logger.info("Perfect score achieved! Processing notification.")

        # 3. 質問情報 (作成者ID, タイトル) を取得
        question_item = questions_table.get_item(Key={'questionId': question_id}).get('Item')
        if not question_item:
            raise Exception("Question not found")
        author_id = question_item.get('authorId')
        question_title = question_item.get('title', '無題')
        
        # もし解答者=作成者なら通知しない
        if solver_id == author_id:
            logger.info("Solver is the author. No notification sent.")
            return {'statusCode': 200, 'body': json.dumps({'message': 'Solver is author.'})}

        # 4. 解答者(solver)のニックネームを取得
        solver_profile = users_table.get_item(Key={'userId': solver_id}).get('Item')
        solver_nickname = solver_profile.get('nickname', 'あるユーザー') if solver_profile else 'あるユーザー'

        # 5. 作成者(author)の通知設定を取得
        author_profile = users_table.get_item(Key={'userId': author_id}).get('Item')
        if not author_profile:
            raise Exception("Author profile not found")
            
        notify_setting = author_profile.get('notifyOnCorrectAnswer', False) # 通知設定 (デフォルトOFF)
        
        if not notify_setting:
            logger.info(f"Author {author_id} notification setting is OFF (notifyOnCorrectAnswer=false/null).")
            return {'statusCode': 200, 'body': json.dumps({'message': 'Author notification setting is off.'})}

        # ★ 6. Devicesテーブルから作成者の全デバイスを取得 (修正箇所)
        try:
            response = devices_table.query(
                KeyConditionExpression=boto3.dynamodb.conditions.Key('userId').eq(author_id)
            )
            devices = response.get('Items', [])
            
            if not devices:
                logger.warning(f"ユーザー {author_id} の登録デバイスが見つかりません。")
                return {'statusCode': 200, 'body': json.dumps({'message': 'No devices found for author.'})}
                
        except ClientError as e:
            logger.error(f"DevicesテーブルのQueryに失敗: {e}")
            raise e

        logger.info(f"ユーザー {author_id} の {len(devices)} 台のデバイスに通知を試みます。")

        # 7. APNsペイロードの作成
        message_body = f"{solver_nickname}さんが、あなたの質問『{question_title}』に全問正解しました！"
        aps_payload = {
            'aps': {
                'alert': {
                    'title': 'おめでとうございます！',
                    'body': message_body
                },
                'sound': 'default',
          
            },
            'customData': {
                'type': 'QuizComplete',
                'questionId': question_id
            }
        }
        message_to_sns = {
            'default': message_body,
            'APNS': json.dumps(aps_payload)
        }

        success_count = 0
        failure_count = 0

        # ★ 8. 各デバイスにPublish (修正箇所)
        for device in devices:
            device_endpoint_arn = device.get('endpointArn')
            if not device_endpoint_arn:
                logger.warning(f"デバイスにendpointArnがありません。スキップします。")
                failure_count += 1
                continue

            try:
                sns_client.publish(
                    TargetArn=device_endpoint_arn,
                    Message=json.dumps(message_to_sns),
                    MessageStructure='json'
                )
                logger.info(f"Publish成功: {device_endpoint_arn}")
                success_count += 1

            except ClientError as e:
                logger.error(f"Publish失敗: {device_endpoint_arn}, Error: {e}")
                failure_count += 1

        logger.info(f"Publish完了: success={success_count}, failure={failure_count}")

        return {
            'statusCode': 200, 
            'body': json.dumps({'message': 'Quiz completion processed successfully.'}, cls=DecimalEncoder)
        }

    except ClientError as e:
        logger.error(f"DynamoDB Error: {e.response['Error']['Message']}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
    except ValueError as ve:
        logger.error(f"Value Error: {ve}")
        return {'statusCode': 400, 'body': json.dumps({'error': str(ve)})}
    except Exception as e:
        logger.error(f"Unexpected Error: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
