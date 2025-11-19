import json
import boto3
import base64
from datetime import datetime
import sys
import subprocess

# python-dateutil をインストール（初回のみ）
try:
    from dateutil.relativedelta import relativedelta
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-t", "/tmp/", "python-dateutil"])
    sys.path.insert(0, '/tmp/')
    from dateutil.relativedelta import relativedelta

# AWS クライアント
s3_client = boto3.client('s3', region_name='ap-northeast-1')
dynamodb = boto3.resource('dynamodb', region_name='ap-northeast-1')

# 設定
S3_BUCKET_NAME = 'question-connection-profiles'
USERS_TABLE_NAME = 'Users'
AWS_REGION = 'ap-northeast-1'
MAX_CHANGES_PER_MONTH = 2  # 月に2回まで

# DynamoDB テーブル
users_table = dynamodb.Table(USERS_TABLE_NAME)

def lambda_handler(event, context):
    """
    POST /users/{userId}/profileImage
    マルチパートフォームデータで受け取った画像をS3にアップロード
    月に2回までの変更制限あり
    """
    try:
        print(f"[START] uploadProfileImage")
        
        # パスパラメータから userId を取得
        user_id = event['pathParameters']['userId']
        print(f"[INFO] userId: {user_id}")
        
        # ========== ステップ1：月内の変更回数をチェック ==========
        user_data = users_table.get_item(Key={'userId': user_id}).get('Item', {})
        print(f"[INFO] user_data retrieved: {user_data.get('userId')}")
        
        # 変更日時のリストを取得
        profile_image_change_dates = user_data.get('profileImageChangeDates', [])
        print(f"[INFO] profileImageChangeDates: {profile_image_change_dates}")
        
        # 今月の変更回数をカウント
        month_change_count = count_changes_in_current_month(profile_image_change_dates)
        print(f"[INFO] month_change_count: {month_change_count}")
        
        # 2回以上の場合はエラーを返す
        if month_change_count >= MAX_CHANGES_PER_MONTH:
            print(f"[ERROR] Monthly limit exceeded: {month_change_count}/{MAX_CHANGES_PER_MONTH}")
            next_month_start = get_next_month_start()
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Monthly change limit exceeded',
                    'message': f'You can change your profile image {MAX_CHANGES_PER_MONTH} times per month. Next change available after {next_month_start}',
                    'changeCount': month_change_count,
                    'maxChanges': MAX_CHANGES_PER_MONTH,
                    'nextAvailableDate': next_month_start
                }),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                }
            }
        
        # ========== ステップ2：リクエストボディから画像データを取得 ==========
        body = event.get('body', '')
        is_base64 = event.get('isBase64Encoded', False)
        
        print(f"[INFO] isBase64Encoded: {is_base64}, body length: {len(body)}")
        
        if is_base64:
            image_data = base64.b64decode(body)
        else:
            image_data = body.encode('utf-8') if isinstance(body, str) else body
        
        print(f"[INFO] image_data length: {len(image_data)}")
        
        # ========== ステップ3：マルチパートフォームデータをパース ==========
        content_type = event.get('headers', {}).get('content-type', '')
        print(f"[INFO] content_type: {content_type}")
        
        if 'boundary=' not in content_type:
            print("[ERROR] Invalid Content-Type")
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid Content-Type'}),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                }
            }
        
        # boundary を抽出
        boundary = content_type.split('boundary=')[1].split(';')[0]
        print(f"[INFO] boundary: {boundary}")
        
        # マルチパートデータから画像を抽出
        image_bytes = extract_image_from_multipart(image_data, boundary)
        
        if not image_bytes:
            print("[ERROR] No image data found")
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'No image data found'}),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                }
            }
        
        print(f"[INFO] extracted image size: {len(image_bytes)}")
        
        # ========== ステップ4：古い画像を S3 から削除 ==========
        old_image_url = user_data.get('profileImageUrl')
        if old_image_url:
            try:
                old_s3_key = extract_s3_key_from_url(old_image_url)
                if old_s3_key:
                    s3_client.delete_object(Bucket=S3_BUCKET_NAME, Key=old_s3_key)
                    print(f"[INFO] Old image deleted: {old_s3_key}")
            except Exception as e:
                print(f"[WARNING] Failed to delete old image: {str(e)}")
        
        # ========== ステップ5：新しい画像を S3 にアップロード ==========
        s3_key = f"profile-images/{user_id}/profile.jpg"
        print(f"[INFO] uploading to S3: {s3_key}")
        
        s3_client.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=s3_key,
            Body=image_bytes,
            ContentType='image/jpeg'
        )
        
        print(f"[INFO] S3 upload success: {s3_key}")
        
        # S3 画像 URL を生成
        image_url = f"https://{S3_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{s3_key}"
        print(f"[INFO] image_url: {image_url}")
        
        # ========== ステップ6：DynamoDB を更新 ==========
        # 変更日時を追加
        now = datetime.utcnow().isoformat() + 'Z'
        new_change_dates = profile_image_change_dates + [now]
        
        # 古い変更日時を削除（1年以上前のものを削除）
        one_year_ago = (datetime.utcnow() - relativedelta(years=1)).isoformat() + 'Z'
        new_change_dates = [date for date in new_change_dates if date > one_year_ago]
        
        users_table.update_item(
            Key={'userId': user_id},
            UpdateExpression='SET profileImageUrl = :url, profileImageChangeDates = :dates, lastProfileImageUpdate = :now',
            ExpressionAttributeValues={
                ':url': image_url,
                ':dates': new_change_dates,
                ':now': now
            }
        )
        
        print(f"[INFO] DynamoDB update success")
        
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'profileImageUrl': image_url,
                'message': 'Profile image updated successfully',
                'changeCount': month_change_count + 1,
                'maxChanges': MAX_CHANGES_PER_MONTH,
                'remainingChanges': MAX_CHANGES_PER_MONTH - (month_change_count + 1)
            }),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
        
        print(f"[SUCCESS] uploadProfileImage completed")
        return response
    
    except Exception as e:
        print(f"[ERROR] Exception: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }


def count_changes_in_current_month(change_dates):
    """
    今月の変更回数をカウント
    """
    try:
        now = datetime.utcnow()
        current_month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        next_month_start = current_month_start + relativedelta(months=1)
        
        count = 0
        for date_str in change_dates:
            date_obj = datetime.fromisoformat(date_str.replace('Z', '+00:00')).replace(tzinfo=None)
            if current_month_start <= date_obj < next_month_start:
                count += 1
        
        print(f"[count_changes_in_current_month] count: {count}, current_month: {current_month_start}, next_month: {next_month_start}")
        return count
    except Exception as e:
        print(f"[count_changes_in_current_month] Error: {str(e)}")
        return 0


def get_next_month_start():
    """
    来月の1日を返す（ISO 8601 形式）
    """
    try:
        now = datetime.utcnow()
        next_month = now + relativedelta(months=1)
        next_month_start = next_month.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        return next_month_start.isoformat() + 'Z'
    except Exception as e:
        print(f"[get_next_month_start] Error: {str(e)}")
        return None


def extract_s3_key_from_url(image_url):
    """
    S3 URL から Key を抽出
    例：https://bucket.s3.region.amazonaws.com/key/path → key/path
    """
    try:
        # https://question-connection-profiles.s3.ap-northeast-1.amazonaws.com/profile-images/userId/profile.jpg
        parts = image_url.split('.amazonaws.com/')
        if len(parts) == 2:
            return parts[1]
        return None
    except Exception as e:
        print(f"[extract_s3_key_from_url] Error: {str(e)}")
        return None


def extract_image_from_multipart(data, boundary):
    """
    マルチパートフォームデータから画像バイナリを抽出
    """
    try:
        print(f"[extract_image_from_multipart] data length: {len(data)}")
        boundary_bytes = boundary.encode('utf-8')
        parts = data.split(b'--' + boundary_bytes)
        
        print(f"[extract_image_from_multipart] parts count: {len(parts)}")
        
        for i, part in enumerate(parts):
            print(f"[extract_image_from_multipart] checking part {i}, length: {len(part)}")
            if b'Content-Disposition: form-data' in part and b'profileImage' in part:
                print(f"[extract_image_from_multipart] found profileImage in part {i}")
                if b'\r\n\r\n' in part:
                    _, body = part.split(b'\r\n\r\n', 1)
                    body = body.rstrip(b'\r\n')
                    print(f"[extract_image_from_multipart] extracted body length: {len(body)}")
                    return body
        
        print("[extract_image_from_multipart] profileImage not found")
        return None
    except Exception as e:
        print(f"[extract_image_from_multipart] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None
