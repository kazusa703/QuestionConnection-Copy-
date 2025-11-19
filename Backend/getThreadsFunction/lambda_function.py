import json
import os
from typing import Any, Dict, List, Optional

import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb")
CORS_ORIGIN = os.environ.get("CORS_ORIGIN", "*")

def _resp(status: int, body: Any) -> Dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": CORS_ORIGIN,
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Methods": "OPTIONS,GET",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }

def _claims(event: Dict[str, Any]) -> Dict[str, Any]:
    return (event.get("requestContext", {}).get("authorizer", {}).get("claims") or {})

def _get_user_id(event: Dict[str, Any]) -> Optional[str]:
    path_params = event.get("pathParameters") or {}
    if "userId" in path_params and path_params["userId"]:
        return str(path_params["userId"])
    qs = event.get("queryStringParameters") or {}
    if "userId" in qs and qs["userId"]:
        return str(qs["userId"])
    return None

def handler(event, context):
    if event.get("httpMethod") == "OPTIONS":
        return _resp(200, {"ok": True})

    threads_table_name = os.environ.get("THREADS_TABLE", "Threads")
    table = dynamodb.Table(threads_table_name)

    print("get_threads: event received")
    claims = _claims(event)
    sub = claims.get("sub")
    print(f"get_threads: claims.sub={sub}")

    user_id = _get_user_id(event)
    print(f"get_threads: requested userId={user_id}")

    if not sub:
        return _resp(401, {"message": "Unauthorized: missing Cognito claims"})
    if not user_id:
        return _resp(400, {"message": "Bad Request: missing userId"})
    if user_id != sub:
        return _resp(403, {"message": "Forbidden: userId mismatch"})

    try:
        items: List[Dict[str, Any]] = []
        scan_kwargs: Dict[str, Any] = {
            "FilterExpression": Attr("participants").contains(user_id)
        }
        while True:
            resp = table.scan(**scan_kwargs)
            items.extend(resp.get("Items", []))
            lek = resp.get("LastEvaluatedKey")
            if not lek:
                break
            scan_kwargs["ExclusiveStartKey"] = lek

        items.sort(key=lambda x: x.get("lastUpdated", ""), reverse=True)
        print(f"get_threads: returning {len(items)} threads")
        return _resp(200, items)

    except Exception as e:
        print(f"get_threads: error {e}")
        return _resp(500, {"message": f"Internal error: {str(e)}"})

def lambda_handler(event, context):
    return handler(event, context)
