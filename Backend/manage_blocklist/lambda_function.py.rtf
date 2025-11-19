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
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  os\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  traceback\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  typing \cf2 \strokec2 import\cf4 \strokec4  Any, Dict, Optional\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  boto3.dynamodb.conditions \cf2 \strokec2 import\cf4 \strokec4  Key\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 CORS_ORIGIN \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "CORS_ORIGIN"\cf4 \strokec4 , \cf6 \strokec6 "*"\cf4 \strokec4 )\cb1 \
\cb3 BLOCKS_TABLE_NAME \strokec5 =\strokec4  os.environ[\cf6 \strokec6 "BLOCKS_TABLE"\cf4 \strokec4 ] \cf7 \strokec7 # \uc0\u29872 \u22659 \u22793 \u25968 \cf4 \cb1 \strokec4 \
\cb3 BLOCKS_GSI_NAME \strokec5 =\strokec4  os.environ[\cf6 \strokec6 "BLOCKS_GSI_NAME"\cf4 \strokec4 ] \cf7 \strokec7 # \uc0\u29872 \u22659 \u22793 \u25968  (blockedId-index)\cf4 \cb1 \strokec4 \
\
\cb3 dynamodb \strokec5 =\strokec4  boto3.resource(\cf6 \strokec6 "dynamodb"\cf4 \strokec4 )\cb1 \
\cb3 table \strokec5 =\strokec4  dynamodb.Table(BLOCKS_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 # --- \uc0\u12504 \u12523 \u12497 \u12540 \u38306 \u25968  ---\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _resp\cf4 \strokec4 (\cf10 \strokec10 status\cf4 \strokec4 : \cf11 \strokec11 int\cf4 \strokec4 , \cf10 \strokec10 body\cf4 \strokec4 : Any) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3         \cf6 \strokec6 "statusCode"\cf4 \strokec4 : status,\cb1 \
\cb3         \cf6 \strokec6 "headers"\cf4 \strokec4 : \{\cb1 \
\cb3             \cf6 \strokec6 "Content-Type"\cf4 \strokec4 : \cf6 \strokec6 "application/json"\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 "Access-Control-Allow-Origin"\cf4 \strokec4 : CORS_ORIGIN,\cb1 \
\cb3             \cf6 \strokec6 "Access-Control-Allow-Headers"\cf4 \strokec4 : \cf6 \strokec6 "*"\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 "Access-Control-Allow-Methods"\cf4 \strokec4 : \cf6 \strokec6 "OPTIONS,GET,POST,DELETE"\cf4 \strokec4 ,\cb1 \
\cb3         \},\cb1 \
\cb3         \cf6 \strokec6 "body"\cf4 \strokec4 : json.dumps(body, \cf10 \strokec10 ensure_ascii\cf4 \strokec5 =\cf8 \strokec8 False\cf4 \strokec4 ),\cb1 \
\cb3     \}\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _get_claims\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 : Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     rc \strokec5 =\strokec4  event.get(\cf6 \strokec6 "requestContext"\cf4 \strokec4 ) \cf8 \strokec8 or\cf4 \strokec4  \{\}\cb1 \
\cb3     authorizer \strokec5 =\strokec4  rc.get(\cf6 \strokec6 "authorizer"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  authorizer \cf8 \strokec8 and\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (authorizer.get(\cf6 \strokec6 "claims"\cf4 \strokec4 ), \cf11 \strokec11 dict\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  authorizer[\cf6 \strokec6 "claims"\cf4 \strokec4 ]\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  authorizer \cf8 \strokec8 and\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (authorizer.get(\cf6 \strokec6 "lambda"\cf4 \strokec4 ), \cf11 \strokec11 dict\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  authorizer[\cf6 \strokec6 "lambda"\cf4 \strokec4 ]\cb1 \
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
\cf7 \cb3 \strokec7 # --- \uc0\u12513 \u12452 \u12531 \u12525 \u12472 \u12483 \u12463  ---\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 add_block\cf4 \strokec4 (\cf10 \strokec10 blocker_id\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 , \cf10 \strokec10 body\cf4 \strokec4 : Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf6 \strokec6 """ \uc0\u12518 \u12540 \u12470 \u12540 \u12434 \u12502 \u12525 \u12483 \u12463 \u12522 \u12473 \u12488 \u12395 \u36861 \u21152  (POST /users/me/block) """\cf4 \cb1 \strokec4 \
\cb3     blocked_user_id \strokec5 =\strokec4  body.get(\cf6 \strokec6 "blockedUserId"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  blocked_user_id \cf8 \strokec8 or\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (blocked_user_id, \cf11 \strokec11 str\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 400\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Bad Request: 'blockedUserId' (string) is required in body."\cf4 \strokec4 \})\cb1 \
\cb3         \cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  blocker_id \strokec5 ==\strokec4  blocked_user_id:\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 400\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Bad Request: Cannot block yourself."\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         item \strokec5 =\strokec4  \{\cb1 \
\cb3             \cf6 \strokec6 "blockerId"\cf4 \strokec4 : blocker_id,   \cf7 \strokec7 # PK\cf4 \cb1 \strokec4 \
\cb3             \cf6 \strokec6 "blockedId"\cf4 \strokec4 : blocked_user_id, \cf7 \strokec7 # SK\cf4 \cb1 \strokec4 \
\cb3         \}\cb1 \
\cb3         table.put_item(\cf10 \strokec10 Item\cf4 \strokec5 =\strokec4 item)\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] User \cf8 \strokec8 \{\cf4 \strokec4 blocker_id\cf8 \strokec8 \}\cf6 \strokec6  blocked \cf8 \strokec8 \{\cf4 \strokec4 blocked_user_id\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 201\cf4 \strokec4 , \{\cf6 \strokec6 "status"\cf4 \strokec4 : \cf6 \strokec6 "blocked"\cf4 \strokec4 , \cf6 \strokec6 "blockedUserId"\cf4 \strokec4 : blocked_user_id\})\cb1 \
\cb3         \cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] Error adding block: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf8 \strokec8 f\cf6 \strokec6 "Internal error: \cf8 \strokec8 \{\cf11 \strokec11 type\cf4 \strokec4 (e).\cf10 \strokec10 __name__\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 remove_block\cf4 \strokec4 (\cf10 \strokec10 blocker_id\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 , \cf10 \strokec10 event\cf4 \strokec4 : Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf6 \strokec6 """ \uc0\u12518 \u12540 \u12470 \u12540 \u12434 \u12502 \u12525 \u12483 \u12463 \u35299 \u38500  (DELETE /users/me/block/\{blockedUserId\}) """\cf4 \cb1 \strokec4 \
\cb3     path_params \strokec5 =\strokec4  event.get(\cf6 \strokec6 "pathParameters"\cf4 \strokec4 ) \cf8 \strokec8 or\cf4 \strokec4  \{\}\cb1 \
\cb3     blocked_user_id \strokec5 =\strokec4  path_params.get(\cf6 \strokec6 "blockedUserId"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  blocked_user_id:\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 400\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Bad Request: Missing \cf8 \strokec8 \{blockedUserId\}\cf6 \strokec6  in path."\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         key \strokec5 =\strokec4  \{\cb1 \
\cb3             \cf6 \strokec6 "blockerId"\cf4 \strokec4 : blocker_id,\cb1 \
\cb3             \cf6 \strokec6 "blockedId"\cf4 \strokec4 : blocked_user_id,\cb1 \
\cb3         \}\cb1 \
\cb3         table.delete_item(\cf10 \strokec10 Key\cf4 \strokec5 =\strokec4 key)\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] User \cf8 \strokec8 \{\cf4 \strokec4 blocker_id\cf8 \strokec8 \}\cf6 \strokec6  unblocked \cf8 \strokec8 \{\cf4 \strokec4 blocked_user_id\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf6 \strokec6 "status"\cf4 \strokec4 : \cf6 \strokec6 "unblocked"\cf4 \strokec4 , \cf6 \strokec6 "unblockedUserId"\cf4 \strokec4 : blocked_user_id\})\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] Error removing block: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf8 \strokec8 f\cf6 \strokec6 "Internal error: \cf8 \strokec8 \{\cf11 \strokec11 type\cf4 \strokec4 (e).\cf10 \strokec10 __name__\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 get_my_blocklist\cf4 \strokec4 (\cf10 \strokec10 blocker_id\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 ) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf6 \strokec6 """ \uc0\u33258 \u20998 \u12364 \u12502 \u12525 \u12483 \u12463 \u12375 \u12383 \u12518 \u12540 \u12470 \u12540 \u12398 \u19968 \u35239 \u12434 \u21462 \u24471  (GET /users/me/blocklist) """\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf7 \strokec7 # PK (blockerId) \uc0\u12391 \u12463 \u12456 \u12522 \cf4 \cb1 \strokec4 \
\cb3         resp \strokec5 =\strokec4  table.query(\cb1 \
\cb3             \cf10 \strokec10 KeyConditionExpression\cf4 \strokec5 =\strokec4 Key(\cf6 \strokec6 "blockerId"\cf4 \strokec4 ).eq(blocker_id),\cb1 \
\cb3             \cf10 \strokec10 ProjectionExpression\cf4 \strokec5 =\cf6 \strokec6 "blockedId"\cf4 \strokec4  \cf7 \strokec7 # \uc0\u30456 \u25163 \u12398 ID\u12384 \u12369 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         )\cb1 \
\cb3         items \strokec5 =\strokec4  resp.get(\cf6 \strokec6 "Items"\cf4 \strokec4 , [])\cb1 \
\cb3         \cf7 \strokec7 # ["id1", "id2", ...] \uc0\u12398 \u12522 \u12473 \u12488 \u12395 \u22793 \u25563 \cf4 \cb1 \strokec4 \
\cb3         blocked_ids \strokec5 =\strokec4  [item[\cf6 \strokec6 "blockedId"\cf4 \strokec4 ] \cf2 \strokec2 for\cf4 \strokec4  item \cf2 \strokec2 in\cf4 \strokec4  items \cf2 \strokec2 if\cf4 \strokec4  \cf6 \strokec6 "blockedId"\cf4 \strokec4  \cf8 \strokec8 in\cf4 \strokec4  item]\cb1 \
\cb3         \cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] User \cf8 \strokec8 \{\cf4 \strokec4 blocker_id\cf8 \strokec8 \}\cf6 \strokec6  fetched blocklist. Count: \cf8 \strokec8 \{\cf9 \strokec9 len\cf4 \strokec4 (blocked_ids)\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf6 \strokec6 "blockedUserIds"\cf4 \strokec4 : blocked_ids\})\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] Error fetching blocklist: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf8 \strokec8 f\cf6 \strokec6 "Internal error: \cf8 \strokec8 \{\cf11 \strokec11 type\cf4 \strokec4 (e).\cf10 \strokec10 __name__\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 # --- \uc0\u9733 \u9733 \u9733  DM\u21463 \u20449 \u25298 \u21542 \u12398 \u12383 \u12417 \u12398 \u38306 \u25968  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 check_if_blocked\cf4 \strokec4 (\cf10 \strokec10 my_user_id\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 , \cf10 \strokec10 event\cf4 \strokec4 : Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf6 \strokec6 """ \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6     \uc0\u30456 \u25163 \u12364 \u33258 \u20998 \u12434 \u12502 \u12525 \u12483 \u12463 \u12375 \u12390 \u12356 \u12427 \u12363 \u30906 \u35469  (GET /users/check-block?targetId=\u30456 \u25163 \u12398 ID)\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6     DM\uc0\u36865 \u20449 API (v2) \u12364 \u20869 \u37096 \u12391 \u21628 \u12403 \u20986 \u12377 \u29992 \cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6     """\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     q_params \strokec5 =\strokec4  event.get(\cf6 \strokec6 "queryStringParameters"\cf4 \strokec4 ) \cf8 \strokec8 or\cf4 \strokec4  \{\}\cb1 \
\cb3     target_id \strokec5 =\strokec4  q_params.get(\cf6 \strokec6 "targetId"\cf4 \strokec4 ) \cf7 \strokec7 # \uc0\u30456 \u25163 \u12398 ID\cf4 \cb1 \strokec4 \
\cb3     \cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  target_id:\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 400\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Bad Request: 'targetId' query parameter is required."\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf7 \strokec7 # GSI (blockedId-index) \uc0\u12434 \u20351 \u12387 \u12390 \u26908 \u32034 \cf4 \cb1 \strokec4 \
\cb3         \cf7 \strokec7 # \uc0\u30456 \u25163 (target_id)\u12364 \u12289 \u33258 \u20998 (my_user_id)\u12434 \u12502 \u12525 \u12483 \u12463 \u12375 \u12390 \u12356 \u12427 \u12363 \cf4 \cb1 \strokec4 \
\cb3         resp \strokec5 =\strokec4  table.query(\cb1 \
\cb3             \cf10 \strokec10 IndexName\cf4 \strokec5 =\strokec4 BLOCKS_GSI_NAME,\cb1 \
\cb3             \cf10 \strokec10 KeyConditionExpression\cf4 \strokec5 =\strokec4 Key(\cf6 \strokec6 "blockedId"\cf4 \strokec4 ).eq(my_user_id) \strokec5 &\strokec4  Key(\cf6 \strokec6 "blockerId"\cf4 \strokec4 ).eq(target_id),\cb1 \
\cb3             \cf10 \strokec10 ProjectionExpression\cf4 \strokec5 =\cf6 \strokec6 "blockerId"\cf4 \strokec4  \cf7 \strokec7 # \uc0\u20309 \u12363 1\u20214 \u12391 \u12418 \u36820 \u12428 \u12400 \u12502 \u12525 \u12483 \u12463 \u12373 \u12428 \u12390 \u12356 \u12427 \cf4 \cb1 \strokec4 \
\cb3         )\cb1 \
\cb3         \cb1 \
\cb3         is_blocked \strokec5 =\strokec4  \cf9 \strokec9 len\cf4 \strokec4 (resp.get(\cf6 \strokec6 "Items"\cf4 \strokec4 , [])) \strokec5 >\strokec4  \cf12 \strokec12 0\cf4 \cb1 \strokec4 \
\cb3         \cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] Check: Is \cf8 \strokec8 \{\cf4 \strokec4 my_user_id\cf8 \strokec8 \}\cf6 \strokec6  blocked by \cf8 \strokec8 \{\cf4 \strokec4 target_id\cf8 \strokec8 \}\cf6 \strokec6 ? Result: \cf8 \strokec8 \{\cf4 \strokec4 is_blocked\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf6 \strokec6 "isBlockedByTarget"\cf4 \strokec4 : is_blocked\})\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] Error checking block status: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf8 \strokec8 f\cf6 \strokec6 "Internal error: \cf8 \strokec8 \{\cf11 \strokec11 type\cf4 \strokec4 (e).\cf10 \strokec10 __name__\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 # --- \uc0\u12495 \u12531 \u12489 \u12521 \u12540  ---\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 if\cf4 \strokec4  event.get(\cf6 \strokec6 "httpMethod"\cf4 \strokec4 ) \strokec5 ==\strokec4  \cf6 \strokec6 "OPTIONS"\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf6 \strokec6 "ok"\cf4 \strokec4 : \cf8 \strokec8 True\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  BLOCKS_TABLE_NAME \cf8 \strokec8 or\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  BLOCKS_GSI_NAME:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf6 \strokec6 "[Block] CRITICAL: Environment variables BLOCKS_TABLE or BLOCKS_GSI_NAME are not set."\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Server configuration error."\cf4 \strokec4 \})\cb1 \
\
\cb3         claims \strokec5 =\strokec4  _get_claims(event)\cb1 \
\cb3         my_user_id \strokec5 =\strokec4  claims.get(\cf6 \strokec6 "sub"\cf4 \strokec4 ) \cf7 \strokec7 # \uc0\u12488 \u12540 \u12463 \u12531 \u12363 \u12425 \u21462 \u24471 \u12375 \u12383 \u33258 \u20998 \u12398 ID\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  my_user_id:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 401\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Unauthorized: Missing 'sub' claim in token."\cf4 \strokec4 \})\cb1 \
\
\cb3         \cf7 \strokec7 # --- \uc0\u12523 \u12540 \u12486 \u12451 \u12531 \u12464  ---\cf4 \cb1 \strokec4 \
\cb3         http_method \strokec5 =\strokec4  event.get(\cf6 \strokec6 "httpMethod"\cf4 \strokec4 , \cf6 \strokec6 ""\cf4 \strokec4 )\cb1 \
\cb3         path \strokec5 =\strokec4  event.get(\cf6 \strokec6 "path"\cf4 \strokec4 , \cf6 \strokec6 ""\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf7 \strokec7 # 1. \uc0\u12502 \u12525 \u12483 \u12463 \u36861 \u21152 : POST /users/me/block\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  http_method \strokec5 ==\strokec4  \cf6 \strokec6 "POST"\cf4 \strokec4  \cf8 \strokec8 and\cf4 \strokec4  path.endswith(\cf6 \strokec6 "/users/me/block"\cf4 \strokec4 ):\cb1 \
\cb3             body \strokec5 =\strokec4  _read_body(event)\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  add_block(my_user_id, body)\cb1 \
\cb3             \cb1 \
\cb3         \cf7 \strokec7 # 2. \uc0\u12502 \u12525 \u12483 \u12463 \u35299 \u38500 : DELETE /users/me/block/\{blockedUserId\}\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  http_method \strokec5 ==\strokec4  \cf6 \strokec6 "DELETE"\cf4 \strokec4  \cf8 \strokec8 and\cf4 \strokec4  \cf6 \strokec6 "/users/me/block/"\cf4 \strokec4  \cf8 \strokec8 in\cf4 \strokec4  path:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  remove_block(my_user_id, event)\cb1 \
\cb3             \cb1 \
\cb3         \cf7 \strokec7 # 3. \uc0\u12502 \u12525 \u12483 \u12463 \u12522 \u12473 \u12488 \u21462 \u24471 : GET /users/me/blocklist\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  http_method \strokec5 ==\strokec4  \cf6 \strokec6 "GET"\cf4 \strokec4  \cf8 \strokec8 and\cf4 \strokec4  path.endswith(\cf6 \strokec6 "/users/me/blocklist"\cf4 \strokec4 ):\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  get_my_blocklist(my_user_id)\cb1 \
\cb3             \cb1 \
\cb3         \cf7 \strokec7 # 4. \uc0\u12502 \u12525 \u12483 \u12463 \u29366 \u24907 \u12481 \u12455 \u12483 \u12463 : GET /users/check-block?targetId=...\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  http_method \strokec5 ==\strokec4  \cf6 \strokec6 "GET"\cf4 \strokec4  \cf8 \strokec8 and\cf4 \strokec4  path.endswith(\cf6 \strokec6 "/users/check-block"\cf4 \strokec4 ):\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  check_if_blocked(my_user_id, event)\cb1 \
\
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 404\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Not Found: Invalid block API route."\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[Block] CRITICAL: Unhandled exception: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (traceback.format_exc())\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf8 \strokec8 f\cf6 \strokec6 "Internal error: \cf8 \strokec8 \{\cf11 \strokec11 type\cf4 \strokec4 (e).\cf10 \strokec10 __name__\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 return\cf4 \strokec4  handler(event, context)\cb1 \
}