{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red0\green0\blue0;\red144\green1\blue18;\red15\green112\blue1;\red0\green0\blue255;\red101\green76\blue29;
\red0\green0\blue109;\red32\green108\blue135;\red19\green118\blue70;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c50196\c0;\cssrgb\c0\c0\c100000;\cssrgb\c47451\c36863\c14902;
\cssrgb\c0\c6275\c50196;\cssrgb\c14902\c49804\c60000;\cssrgb\c3529\c52549\c34510;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json, os, uuid\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  datetime \cf2 \strokec2 import\cf4 \strokec4  datetime, timezone\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  typing \cf2 \strokec2 import\cf4 \strokec4  Any, Dict, Optional\cb1 \
\
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 CORS_ORIGIN \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "CORS_ORIGIN"\cf4 \strokec4 , \cf6 \strokec6 "*"\cf4 \strokec4 )\cb1 \
\cb3 REPORTS_TABLE \strokec5 =\strokec4  os.environ[\cf6 \strokec6 "REPORTS_TABLE"\cf4 \strokec4 ] \cf7 \strokec7 # \uc0\u29872 \u22659 \u22793 \u25968 \u12363 \u12425 \u12486 \u12540 \u12502 \u12523 \u21517 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\
\cb3 dynamodb \strokec5 =\strokec4  boto3.resource(\cf6 \strokec6 "dynamodb"\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _resp\cf4 \strokec4 (\cf10 \strokec10 status\cf4 \strokec4 : \cf11 \strokec11 int\cf4 \strokec4 , \cf10 \strokec10 body\cf4 \strokec4 : Any, \cf10 \strokec10 headers\cf4 \strokec4 : Optional[Dict[\cf11 \strokec11 str\cf4 \strokec4 , \cf11 \strokec11 str\cf4 \strokec4 ]] \strokec5 =\strokec4  \cf8 \strokec8 None\cf4 \strokec4 ) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     base_headers \strokec5 =\strokec4  \{\cb1 \
\cb3         \cf6 \strokec6 "Content-Type"\cf4 \strokec4 : \cf6 \strokec6 "application/json"\cf4 \strokec4 ,\cb1 \
\cb3         \cf6 \strokec6 "Access-Control-Allow-Origin"\cf4 \strokec4 : CORS_ORIGIN,\cb1 \
\cb3         \cf6 \strokec6 "Access-Control-Allow-Headers"\cf4 \strokec4 : \cf6 \strokec6 "*"\cf4 \strokec4 ,\cb1 \
\cb3         \cf6 \strokec6 "Access-Control-Allow-Methods"\cf4 \strokec4 : \cf6 \strokec6 "OPTIONS,POST"\cf4 \strokec4 , \cf7 \strokec7 # POST\uc0\u35377 \u21487 \cf4 \cb1 \strokec4 \
\cb3     \}\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  headers:\cb1 \
\cb3         base_headers.update(headers)\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3         \cf6 \strokec6 "statusCode"\cf4 \strokec4 : status,\cb1 \
\cb3         \cf6 \strokec6 "headers"\cf4 \strokec4 : base_headers,\cb1 \
\cb3         \cf6 \strokec6 "body"\cf4 \strokec4 : json.dumps(body, \cf10 \strokec10 ensure_ascii\cf4 \strokec5 =\cf8 \strokec8 False\cf4 \strokec4 ),\cb1 \
\cb3     \}\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _get_claims\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 : Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf7 \strokec7 # (delete_user (v4) \uc0\u12392 \u21516 \u12376 \u22533 \u29282 \u12394 \u12463 \u12524 \u12540 \u12512 \u21462 \u24471 \u12525 \u12472 \u12483 \u12463 )\cf4 \cb1 \strokec4 \
\cb3     rc \strokec5 =\strokec4  event.get(\cf6 \strokec6 "requestContext"\cf4 \strokec4 ) \cf8 \strokec8 or\cf4 \strokec4  \{\}\cb1 \
\cb3     authorizer \strokec5 =\strokec4  rc.get(\cf6 \strokec6 "authorizer"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  authorizer \cf8 \strokec8 and\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (authorizer.get(\cf6 \strokec6 "claims"\cf4 \strokec4 ), \cf11 \strokec11 dict\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  authorizer[\cf6 \strokec6 "claims"\cf4 \strokec4 ]\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  authorizer \cf8 \strokec8 and\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (authorizer.get(\cf6 \strokec6 "lambda"\cf4 \strokec4 ), \cf11 \strokec11 dict\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  authorizer[\cf6 \strokec6 "lambda"\cf4 \strokec4 ]\cb1 \
\cb3     \cf9 \strokec9 print\cf4 \strokec4 (\cf6 \strokec6 "[report_abuse] Warning: Could not find claims in requestContext.authorizer"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\}\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _read_body\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 : Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     body \strokec5 =\strokec4  event.get(\cf6 \strokec6 "body"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  body: \cf2 \strokec2 return\cf4 \strokec4  \{\}\cb1 \
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  json.loads(body)\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  json.JSONDecodeError:\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\}\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _iso_now\cf4 \strokec4 () -> \cf11 \strokec11 str\cf4 \strokec4 :\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 return\cf4 \strokec4  datetime.now(timezone.utc).isoformat()\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 if\cf4 \strokec4  event.get(\cf6 \strokec6 "httpMethod"\cf4 \strokec4 ) \strokec5 ==\strokec4  \cf6 \strokec6 "OPTIONS"\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf6 \strokec6 "ok"\cf4 \strokec4 : \cf8 \strokec8 True\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  REPORTS_TABLE:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf6 \strokec6 "[report_abuse] CRITICAL: REPORTS_TABLE is not set."\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Server configuration error: Missing reports table."\cf4 \strokec4 \})\cb1 \
\
\cb3         claims \strokec5 =\strokec4  _get_claims(event)\cb1 \
\cb3         reporter_user_id \strokec5 =\strokec4  claims.get(\cf6 \strokec6 "sub"\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  reporter_user_id:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 401\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Unauthorized: Missing 'sub' claim in token."\cf4 \strokec4 \})\cb1 \
\
\cb3         body \strokec5 =\strokec4  _read_body(event)\cb1 \
\cb3         target_type \strokec5 =\strokec4  body.get(\cf6 \strokec6 "targetType"\cf4 \strokec4 ) \cf7 \strokec7 # \uc0\u20363 : "question"\cf4 \cb1 \strokec4 \
\cb3         target_id \strokec5 =\strokec4  body.get(\cf6 \strokec6 "targetId"\cf4 \strokec4 )   \cf7 \strokec7 # \uc0\u20363 : "question-uuid-..."\cf4 \cb1 \strokec4 \
\cb3         reason \strokec5 =\strokec4  body.get(\cf6 \strokec6 "reason"\cf4 \strokec4 )     \cf7 \strokec7 # \uc0\u20363 : "inappropriate"\cf4 \cb1 \strokec4 \
\cb3         detail \strokec5 =\strokec4  body.get(\cf6 \strokec6 "detail"\cf4 \strokec4 , \cf6 \strokec6 ""\cf4 \strokec4 ) \cf7 \strokec7 # \uc0\u20219 \u24847 \u12398 \u35443 \u32048 \u12486 \u12461 \u12473 \u12488 \cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  (target_type \cf8 \strokec8 and\cf4 \strokec4  target_id \cf8 \strokec8 and\cf4 \strokec4  reason):\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 400\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Bad Request: targetType, targetId, and reason are required."\cf4 \strokec4 \})\cb1 \
\
\cb3         report_id \strokec5 =\strokec4  \cf11 \strokec11 str\cf4 \strokec4 (uuid.uuid4())\cb1 \
\cb3         created_at \strokec5 =\strokec4  _iso_now()\cb1 \
\
\cb3         item \strokec5 =\strokec4  \{\cb1 \
\cb3             \cf6 \strokec6 "reportId"\cf4 \strokec4 : report_id,\cb1 \
\cb3             \cf6 \strokec6 "reporterUserId"\cf4 \strokec4 : reporter_user_id,\cb1 \
\cb3             \cf6 \strokec6 "targetType"\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 (target_type),\cb1 \
\cb3             \cf6 \strokec6 "targetId"\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 (target_id),\cb1 \
\cb3             \cf6 \strokec6 "reason"\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 (reason),\cb1 \
\cb3             \cf6 \strokec6 "detail"\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 (detail) \cf2 \strokec2 if\cf4 \strokec4  detail \cf2 \strokec2 else\cf4 \strokec4  \cf6 \strokec6 ""\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 "createdAt"\cf4 \strokec4 : created_at,\cb1 \
\cb3             \cf6 \strokec6 "status"\cf4 \strokec4 : \cf6 \strokec6 "received"\cf4 \strokec4 , \cf7 \strokec7 # \uc0\u21021 \u26399 \u12473 \u12486 \u12540 \u12479 \u12473 \cf4 \cb1 \strokec4 \
\cb3         \}\cb1 \
\cb3         \cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[report_abuse] Received report \cf8 \strokec8 \{\cf4 \strokec4 report_id\cf8 \strokec8 \}\cf6 \strokec6  from user \cf8 \strokec8 \{\cf4 \strokec4 reporter_user_id\cf8 \strokec8 \}\cf6 \strokec6  for \cf8 \strokec8 \{\cf4 \strokec4 target_type\cf8 \strokec8 \}\cf6 \strokec6 :\cf8 \strokec8 \{\cf4 \strokec4 target_id\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\
\cb3         table \strokec5 =\strokec4  dynamodb.Table(REPORTS_TABLE)\cb1 \
\cb3         table.put_item(\cf10 \strokec10 Item\cf4 \strokec5 =\strokec4 item)\cb1 \
\
\cb3         \cf7 \strokec7 # 201 Created\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 201\cf4 \strokec4 , \{\cf6 \strokec6 "reportId"\cf4 \strokec4 : report_id, \cf6 \strokec6 "status"\cf4 \strokec4 : \cf6 \strokec6 "received"\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[report_abuse] CRITICAL: Unhandled exception: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (traceback.format_exc())\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf8 \strokec8 f\cf6 \strokec6 "Internal error: \cf8 \strokec8 \{\cf11 \strokec11 type\cf4 \strokec4 (e).\cf10 \strokec10 __name__\cf8 \strokec8 \}\cf6 \strokec6 : \cf8 \strokec8 \{\cf11 \strokec11 str\cf4 \strokec4 (e)\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 return\cf4 \strokec4  handler(event, context)\cb1 \
}