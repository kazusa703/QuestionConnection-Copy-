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
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json, os, boto3, traceback\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  boto3.dynamodb.conditions \cf2 \strokec2 import\cf4 \strokec4  Key\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  typing \cf2 \strokec2 import\cf4 \strokec4  Any, Dict, Optional\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 CORS_ORIGIN \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "CORS_ORIGIN"\cf4 \strokec4 , \cf6 \strokec6 "*"\cf4 \strokec4 )\cb1 \
\cb3 USER_POOL_ID \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "COGNITO_USER_POOL_ID"\cf4 \strokec4 , \cf6 \strokec6 ""\cf4 \strokec4 )\cb1 \
\cb3 BOOKMARKS_TABLE_NAME \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "BOOKMARKS_TABLE"\cf4 \strokec4 , \cf6 \strokec6 ""\cf4 \strokec4 )\cb1 \
\cb3 USER_PROFILE_TABLE_NAME \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "USER_PROFILE_TABLE"\cf4 \strokec4 , \cf6 \strokec6 ""\cf4 \strokec4 )\cb1 \
\
\cb3 cognito_client \strokec5 =\strokec4  boto3.client(\cf6 \strokec6 "cognito-idp"\cf4 \strokec4 )\cb1 \
\cb3 dynamodb \strokec5 =\strokec4  boto3.resource(\cf6 \strokec6 "dynamodb"\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 # --- Helper Functions (v4\uc0\u12363 \u12425 \u22793 \u26356 \u12394 \u12375 ) ---\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _resp\cf4 \strokec4 (\cf10 \strokec10 status\cf4 \strokec4 : \cf11 \strokec11 int\cf4 \strokec4 , \cf10 \strokec10 body\cf4 \strokec4 : Any, \cf10 \strokec10 headers\cf4 \strokec4 : Optional[Dict[\cf11 \strokec11 str\cf4 \strokec4 , \cf11 \strokec11 str\cf4 \strokec4 ]] \strokec5 =\strokec4  \cf8 \strokec8 None\cf4 \strokec4 ) -> Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     base_headers \strokec5 =\strokec4  \{\cb1 \
\cb3         \cf6 \strokec6 "Content-Type"\cf4 \strokec4 : \cf6 \strokec6 "application/json"\cf4 \strokec4 ,\cb1 \
\cb3         \cf6 \strokec6 "Access-Control-Allow-Origin"\cf4 \strokec4 : CORS_ORIGIN,\cb1 \
\cb3         \cf6 \strokec6 "Access-Control-Allow-Headers"\cf4 \strokec4 : \cf6 \strokec6 "*"\cf4 \strokec4 ,\cb1 \
\cb3         \cf6 \strokec6 "Access-Control-Allow-Methods"\cf4 \strokec4 : \cf6 \strokec6 "OPTIONS,DELETE"\cf4 \strokec4 ,\cb1 \
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
\cf4 \cb3     rc \strokec5 =\strokec4  event.get(\cf6 \strokec6 "requestContext"\cf4 \strokec4 ) \cf8 \strokec8 or\cf4 \strokec4  \{\}\cb1 \
\cb3     authorizer \strokec5 =\strokec4  rc.get(\cf6 \strokec6 "authorizer"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  authorizer \cf8 \strokec8 and\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (authorizer.get(\cf6 \strokec6 "claims"\cf4 \strokec4 ), \cf11 \strokec11 dict\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  authorizer[\cf6 \strokec6 "claims"\cf4 \strokec4 ]\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  authorizer \cf8 \strokec8 and\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (authorizer.get(\cf6 \strokec6 "lambda"\cf4 \strokec4 ), \cf11 \strokec11 dict\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  authorizer[\cf6 \strokec6 "lambda"\cf4 \strokec4 ]\cb1 \
\cb3     \cf9 \strokec9 print\cf4 \strokec4 (\cf6 \strokec6 "[delete_user] Warning: Could not find claims in requestContext.authorizer"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\}\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _get_cognito_username\cf4 \strokec4 (\cf10 \strokec10 claims\cf4 \strokec4 : Dict[\cf11 \strokec11 str\cf4 \strokec4 , Any]) -> Optional[\cf11 \strokec11 str\cf4 \strokec4 ]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 if\cf4 \strokec4  claims.get(\cf6 \strokec6 "cognito:username"\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf11 \strokec11 str\cf4 \strokec4 (claims[\cf6 \strokec6 "cognito:username"\cf4 \strokec4 ])\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  claims.get(\cf6 \strokec6 "username"\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf11 \strokec11 str\cf4 \strokec4 (claims[\cf6 \strokec6 "username"\cf4 \strokec4 ])\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  claims.get(\cf6 \strokec6 "sub"\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf11 \strokec11 str\cf4 \strokec4 (claims[\cf6 \strokec6 "sub"\cf4 \strokec4 ])\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  \cf8 \strokec8 None\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 # --- \uc0\u9733 \u9733 \u9733  \u12371 \u12371 \u12363 \u12425  v5 \u12391 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 _delete_dynamodb_data\cf4 \strokec4 (\cf10 \strokec10 user_id\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf6 \strokec6 """\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6     Cognito\uc0\u21066 \u38500 \u24460 \u12289 DynamoDB\u12395 \u27531 \u12387 \u12383 \u12518 \u12540 \u12470 \u12540 \u22266 \u26377 \u12487 \u12540 \u12479 \u12434 \u12463 \u12522 \u12540 \u12531 \u12450 \u12483 \u12503 \u12377 \u12427 \cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6     """\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cb1 \
\cb3     \cf7 \strokec7 # 1. UserProfile \uc0\u12398 \u21066 \u38500 \cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  USER_PROFILE_TABLE_NAME:\cb1 \
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             profile_table \strokec5 =\strokec4  dynamodb.Table(USER_PROFILE_TABLE_NAME)\cb1 \
\cb3             \cf7 \strokec7 # UserProfile \uc0\u12398 PK\u12364  'userId' \u12391 \u12354 \u12427 \u21069 \u25552 \cf4 \cb1 \strokec4 \
\cb3             profile_table.delete_item(\cf10 \strokec10 Key\cf4 \strokec5 =\strokec4 \{\cf6 \strokec6 "userId"\cf4 \strokec4 : user_id\})\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] UserProfile deleted for: \cf8 \strokec8 \{\cf4 \strokec4 user_id\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Error deleting from UserProfile: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3             \cf7 \strokec7 # \uc0\u12456 \u12521 \u12540 \u12391 \u12418 \u32154 \u34892 \u65288 Cognito\u21066 \u38500 \u12364 \u12513 \u12452 \u12531 \u12398 \u12383 \u12417 \u65289 \cf4 \cb1 \strokec4 \
\
\cb3     \cf7 \strokec7 # 2. Bookmarks \uc0\u12398 \u21066 \u38500  (GSI 'userId-index' \u12434 \u20351 \u12387 \u12390 \u20840 \u20214 \u26908 \u32034 )\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  BOOKMARKS_TABLE_NAME:\cb1 \
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             bookmarks_table \strokec5 =\strokec4  dynamodb.Table(BOOKMARKS_TABLE_NAME)\cb1 \
\cb3             \cf7 \strokec7 # Bookmarks\uc0\u12364  'bookmarkId' (PK), 'userId' (GSI) \u12398 \u21069 \u25552 \cf4 \cb1 \strokec4 \
\cb3             \cf7 \strokec7 # GSI \uc0\u12434 \u12463 \u12456 \u12522 \u12375 \u12390 \u12289 \u12381 \u12398 \u12518 \u12540 \u12470 \u12540 \u12398 \u20840 \u12502 \u12483 \u12463 \u12510 \u12540 \u12463 ID\u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3             query_kwargs \strokec5 =\strokec4  \{\cb1 \
\cb3                 \cf6 \strokec6 "IndexName"\cf4 \strokec4 : \cf6 \strokec6 "userId-index"\cf4 \strokec4 , \cf7 \strokec7 # \uc0\u9733 \u12418 \u12375 GSI\u21517 \u12364 \u36949 \u12358 \u12394 \u12425 \u35201 \u20462 \u27491 \cf4 \cb1 \strokec4 \
\cb3                 \cf6 \strokec6 "KeyConditionExpression"\cf4 \strokec4 : Key(\cf6 \strokec6 "userId"\cf4 \strokec4 ).eq(user_id),\cb1 \
\cb3                 \cf6 \strokec6 "ProjectionExpression"\cf4 \strokec4 : \cf6 \strokec6 "bookmarkId"\cf4 \strokec4 , \cf7 \strokec7 # PK\uc0\u12398 \u12415 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3             \}\cb1 \
\cb3             items_to_delete \strokec5 =\strokec4  []\cb1 \
\cb3             \cb1 \
\cb3             \cf2 \strokec2 while\cf4 \strokec4  \cf8 \strokec8 True\cf4 \strokec4 :\cb1 \
\cb3                 resp \strokec5 =\strokec4  bookmarks_table.query(\strokec5 **\strokec4 query_kwargs)\cb1 \
\cb3                 items_to_delete.extend(resp.get(\cf6 \strokec6 "Items"\cf4 \strokec4 , []))\cb1 \
\cb3                 lek \strokec5 =\strokec4  resp.get(\cf6 \strokec6 "LastEvaluatedKey"\cf4 \strokec4 )\cb1 \
\cb3                 \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  lek: \cf2 \strokec2 break\cf4 \cb1 \strokec4 \
\cb3                 query_kwargs[\cf6 \strokec6 "ExclusiveStartKey"\cf4 \strokec4 ] \strokec5 =\strokec4  lek\cb1 \
\
\cb3             \cf2 \strokec2 if\cf4 \strokec4  items_to_delete:\cb1 \
\cb3                 \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Found \cf8 \strokec8 \{\cf9 \strokec9 len\cf4 \strokec4 (items_to_delete)\cf8 \strokec8 \}\cf6 \strokec6  bookmarks to delete for user: \cf8 \strokec8 \{\cf4 \strokec4 user_id\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3                 \cf7 \strokec7 # BatchWriteItem \uc0\u12391 \u19968 \u25324 \u21066 \u38500 \cf4 \cb1 \strokec4 \
\cb3                 \cf2 \strokec2 with\cf4 \strokec4  bookmarks_table.batch_writer() \cf2 \strokec2 as\cf4 \strokec4  batch:\cb1 \
\cb3                     \cf2 \strokec2 for\cf4 \strokec4  item \cf2 \strokec2 in\cf4 \strokec4  items_to_delete:\cb1 \
\cb3                         \cf7 \strokec7 # item \uc0\u12399  \{"bookmarkId": "..."\} \u12398 \u24418 \cf4 \cb1 \strokec4 \
\cb3                         batch.delete_item(\cf10 \strokec10 Key\cf4 \strokec5 =\strokec4 \{\cf6 \strokec6 "bookmarkId"\cf4 \strokec4 : item[\cf6 \strokec6 "bookmarkId"\cf4 \strokec4 ]\})\cb1 \
\cb3                 \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Bookmarks deleted successfully."\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 else\cf4 \strokec4 :\cb1 \
\cb3                 \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] No bookmarks found for user: \cf8 \strokec8 \{\cf4 \strokec4 user_id\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3                 \cb1 \
\cb3         \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Error cleaning up Bookmarks: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3             \cf7 \strokec7 # \uc0\u12456 \u12521 \u12540 \u12391 \u12418 \u32154 \u34892 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 # --- \uc0\u9733 \u9733 \u9733  \u12371 \u12371 \u12414 \u12391  v5 \u12391 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 if\cf4 \strokec4  event.get(\cf6 \strokec6 "httpMethod"\cf4 \strokec4 ) \strokec5 ==\strokec4  \cf6 \strokec6 "OPTIONS"\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf6 \strokec6 "ok"\cf4 \strokec4 : \cf8 \strokec8 True\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  USER_POOL_ID:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf6 \strokec6 "[delete_user] CRITICAL: COGNITO_USER_POOL_ID is not set in environment variables."\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Server configuration error: Missing User Pool ID."\cf4 \strokec4 \})\cb1 \
\
\cb3         path_params \strokec5 =\strokec4  event.get(\cf6 \strokec6 "pathParameters"\cf4 \strokec4 ) \cf8 \strokec8 or\cf4 \strokec4  \{\}\cb1 \
\cb3         user_id_from_path \strokec5 =\strokec4  path_params.get(\cf6 \strokec6 "userId"\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  user_id_from_path:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 400\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Bad Request: Missing userId in path."\cf4 \strokec4 \})\cb1 \
\
\cb3         claims \strokec5 =\strokec4  _get_claims(event)\cb1 \
\cb3         user_sub_from_token \strokec5 =\strokec4  claims.get(\cf6 \strokec6 "sub"\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  user_sub_from_token:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 401\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Unauthorized: Missing 'sub' claim in token."\cf4 \strokec4 \})\cb1 \
\cb3         \cb1 \
\cb3         cognito_username \strokec5 =\strokec4  _get_cognito_username(claims)\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  cognito_username:\cb1 \
\cb3              \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 401\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Unauthorized: Could not determine cognito username from token."\cf4 \strokec4 \})\cb1 \
\
\cb3         \cf2 \strokec2 if\cf4 \strokec4  user_id_from_path \strokec5 !=\strokec4  user_sub_from_token:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] FORBIDDEN: Token sub '\cf8 \strokec8 \{\cf4 \strokec4 user_sub_from_token\cf8 \strokec8 \}\cf6 \strokec6 ' does not match path userId '\cf8 \strokec8 \{\cf4 \strokec4 user_id_from_path\cf8 \strokec8 \}\cf6 \strokec6 '"\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 403\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Forbidden: You can only delete your own account."\cf4 \strokec4 \})\cb1 \
\cb3         \cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Auth OK. Attempting to delete user. sub=\cf8 \strokec8 \{\cf4 \strokec4 user_sub_from_token\cf8 \strokec8 \}\cf6 \strokec6 , cognito_username=\cf8 \strokec8 \{\cf4 \strokec4 cognito_username\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf7 \strokec7 # --- 4. Cognito\uc0\u12363 \u12425 \u12518 \u12540 \u12470 \u12540 \u12434 \u21066 \u38500  ---\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             cognito_client.admin_delete_user(\cb1 \
\cb3                 \cf10 \strokec10 UserPoolId\cf4 \strokec5 =\strokec4 USER_POOL_ID,\cb1 \
\cb3                 \cf10 \strokec10 Username\cf4 \strokec5 =\strokec4 cognito_username\cb1 \
\cb3             )\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Cognito user deleted successfully: \cf8 \strokec8 \{\cf4 \strokec4 cognito_username\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Warning: cognito_client.admin_delete_user failed. Error: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3             \cf7 \strokec7 # Cognito\uc0\u20596 \u12398 \u21066 \u38500 \u12395 \u22833 \u25943 \u12375 \u12383 \u12425 \u12289 DB\u21066 \u38500 \u12418 \u12379 \u12378 \u12395 \u12371 \u12371 \u12391 \u12456 \u12521 \u12540 \u12434 \u36820 \u12377 \u12398 \u12364 \u23433 \u20840 \cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 raise\cf4 \strokec4  e \cf7 \strokec7 # \uc0\u9733 v5: \u22833 \u25943 \u26178 \u12399 \u12456 \u12521 \u12540 \u12434 \u25237 \u12370 \u12390 \u32066 \u20102 \u12377 \u12427 \cf4 \cb1 \strokec4 \
\
\cb3         \cf7 \strokec7 # --- 5. \uc0\u38306 \u36899 DB\u12487 \u12540 \u12479 \u12398 \u21066 \u38500  (v5\u12391 \u23455 \u35013 ) ---\cf4 \cb1 \strokec4 \
\cb3         _delete_dynamodb_data(user_sub_from_token)\cb1 \
\
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "[delete_user] Account deletion process completed for sub: \cf8 \strokec8 \{\cf4 \strokec4 user_sub_from_token\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Account deleted successfully."\cf4 \strokec4 \})\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf6 \strokec6 "[delete_user] CRITICAL: Unhandled exception occurred."\cf4 \strokec4 )\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (traceback.format_exc())\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf12 \strokec12 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf8 \strokec8 f\cf6 \strokec6 "Failed to delete account: \cf8 \strokec8 \{\cf11 \strokec11 type\cf4 \strokec4 (e).\cf10 \strokec10 __name__\cf8 \strokec8 \}\cf6 \strokec6 : \cf8 \strokec8 \{\cf11 \strokec11 str\cf4 \strokec4 (e)\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 return\cf4 \strokec4  handler(event, context)\cb1 \
}