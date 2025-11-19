import json
import os
import uuid
import secrets
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import boto3

dynamodb = boto3.resource("dynamodb")

CORS_ORIGIN = os.environ.get("CORS_ORIGIN", "*")


def _resp(status: int, body: Any, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    base_headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": CORS_ORIGIN,
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "OPTIONS,POST",
    }
    if headers:
        base_headers.update(headers)
    return {
        "statusCode": status,
        "headers": base_headers,
        "body": json.dumps(body, ensure_ascii=False),
    }


def _get_claims(event: Dict[str, Any]) -> Dict[str, Any]:
    rc = event.get("requestContext") or {}
    authz = rc.get("authorizer") or {}
    claims = authz.get("claims")
    if isinstance(claims, dict):
        return claims
    return {}


def _read_body(event: Dict[str, Any]) -> Dict[str, Any]:
    body = event.get("body")
    if not body:
        return {}
    if event.get("isBase64Encoded"):
        import base64
        body = base64.b64decode(body).decode("utf-8")
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return {}


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _non_empty_str(val: Any, field: str) -> str:
    if not isinstance(val, str) or not val.strip():
        raise ValueError(f"{field} must be a non-empty string.")
    return val.strip()


def _normalize_str_or_none(val: Any) -> Optional[str]:
    if val is None:
        return None
    if not isinstance(val, str):
        raise ValueError("Value must be a string or null.")
    s = val.strip()
    return s if s else None


def _validate_tags(val: Any) -> List[str]:
    if val is None:
        return []
    if not isinstance(val, list):
        raise ValueError("tags must be an array of strings.")
    out: List[str] = []
    for t in val:
        if not isinstance(t, str):
            raise ValueError("tags must be an array of strings.")
        s = t.strip()
        if s:
            out.append(s)
    return out


def _validate_quiz_items(val: Any) -> List[Dict[str, Any]]:
    if not isinstance(val, list) or len(val) == 0:
        raise ValueError("quizItems must be a non-empty array.")

    validated: List[Dict[str, Any]] = []
    for i, item in enumerate(val, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"quizItems[{i}] must be an object.")
        qid = _non_empty_str(item.get("id"), f"quizItems[{i}].id")
        qtext = _non_empty_str(item.get("questionText"), f"quizItems[{i}].questionText")

        choices = item.get("choices")
        if not isinstance(choices, list) or len(choices) < 2:
            raise ValueError(f"quizItems[{i}].choices must be an array with at least 2 items.")

        vchoices: List[Dict[str, str]] = []
        choice_ids: List[str] = []
        for j, ch in enumerate(choices, start=1):
            if not isinstance(ch, dict):
                raise ValueError(f"quizItems[{i}].choices[{j}] must be an object.")
            cid = _non_empty_str(ch.get("id"), f"quizItems[{i}].choices[{j}].id")
            ctext = _non_empty_str(ch.get("text"), f"quizItems[{i}].choices[{j}].text")
            vchoices.append({"id": cid, "text": ctext})
            choice_ids.append(cid)

        correct = _non_empty_str(item.get("correctAnswerId"), f"quizItems[{i}].correctAnswerId")
        if correct not in choice_ids:
            raise ValueError(
                f"quizItems[{i}].correctAnswerId must match one of the choices' ids."
            )

        validated.append(
            {
                "id": qid,
                "questionText": qtext,
                "choices": vchoices,
                "correctAnswerId": correct,
            }
        )
    return validated


# 衝突しにくく読みやすい英数字（0/1/O/I を除外）
_ALPHABET = "23456789abcdefghjkmnpqrstuvwxyz"
def _gen_share_code(length: int = 10) -> str:
    return "".join(secrets.choice(_ALPHABET) for _ in range(length))


def handler(event, context):
    # CORS preflight
    if event.get("httpMethod") == "OPTIONS":
        return _resp(200, {"ok": True})

    # 環境変数をここで取得（INITで落ちないようにする）
    table_name = os.environ.get("QUESTIONS_TABLE")
    if not table_name:
        return _resp(500, {"message": "Server misconfiguration: QUESTIONS_TABLE is not set."})
    table = dynamodb.Table(table_name)

    # 認証
    claims = _get_claims(event)
    user_sub = claims.get("sub")
    if not user_sub:
        return _resp(401, {"message": "Unauthorized: missing Cognito claims."})

    # 本文
    body = _read_body(event)
    if not body:
        return _resp(400, {"message": "Invalid JSON body."})

    try:
        # 必須
        title = _non_empty_str(body.get("title"), "title")
        author_id = _non_empty_str(body.get("authorId"), "authorId")
        quiz_items = _validate_quiz_items(body.get("quizItems"))

        # 認可: authorId はトークンのsubと一致
        if author_id != user_sub:
            return _resp(403, {"message": "Forbidden: authorId does not match token subject."})

        # 任意
        purpose = _normalize_str_or_none(body.get("purpose"))
        tags = _validate_tags(body.get("tags"))
        remarks_raw = body.get("remarks", "")
        if not isinstance(remarks_raw, str):
            return _resp(400, {"message": "remarks must be a string."})
        remarks = remarks_raw.strip()

        dm_invite_message = _normalize_str_or_none(body.get("dmInviteMessage"))

        # questionId はクライアント提供を優先
        question_id = body.get("questionId")
        if question_id is not None:
            question_id = _non_empty_str(question_id, "questionId")
        else:
            question_id = str(uuid.uuid4())

        created_at = _iso_now()
        share_code = _gen_share_code(10)

        item: Dict[str, Any] = {
            "questionId": question_id,
            "title": title,
            "authorId": author_id,
            "quizItems": quiz_items,
            "createdAt": created_at,
            "remarks": remarks,
            "tags": tags,
            "shareCode": share_code,
        }
        if purpose is not None:
            item["purpose"] = purpose
        if dm_invite_message is not None:
            item["dmInviteMessage"] = dm_invite_message

        # デバッグログ（値が来ているか確認）
        print(f"[create_question] user_sub={user_sub} qid={question_id} shareCode={share_code} has_dmInvite={dm_invite_message is not None}")

        table.put_item(Item=item)

        # 201 Created
        return _resp(201, item)

    except ValueError as ve:
        return _resp(400, {"message": str(ve)})
    except Exception as e:
        return _resp(500, {"message": f"Internal error: {str(e)}"})


def lambda_handler(event, context):
    return handler(event, context)
