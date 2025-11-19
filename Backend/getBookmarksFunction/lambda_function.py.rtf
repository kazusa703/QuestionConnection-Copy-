{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red15\green112\blue1;\red255\green255\blue255;\red45\green45\blue45;
\red157\green0\blue210;\red0\green0\blue0;\red144\green1\blue18;\red0\green0\blue255;\red101\green76\blue29;
\red0\green0\blue109;\red32\green108\blue135;\red19\green118\blue70;}
{\*\expandedcolortbl;;\cssrgb\c0\c50196\c0;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c68627\c0\c85882;\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c0\c100000;\cssrgb\c47451\c36863\c14902;
\cssrgb\c0\c6275\c50196;\cssrgb\c14902\c49804\c60000;\cssrgb\c3529\c52549\c34510;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 # lambda_function.py for getBookmarksFunction\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 import\cf4 \strokec4  json\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  boto3\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  os\cb1 \
\cf5 \cb3 \strokec5 from\cf4 \strokec4  boto3.dynamodb.conditions \cf5 \strokec5 import\cf4 \strokec4  Key\cb1 \
\cf5 \cb3 \strokec5 from\cf4 \strokec4  botocore.exceptions \cf5 \strokec5 import\cf4 \strokec4  ClientError\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 # DynamoDB\uc0\u12486 \u12540 \u12502 \u12523 \u21517  (\u29872 \u22659 \u22793 \u25968 \u12363 \u12425 \u21462 \u24471 )\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 BOOKMARKS_TABLE_NAME \strokec6 =\strokec4  os.environ.get(\cf7 \strokec7 'BOOKMARKS_TABLE_NAME'\cf4 \strokec4 , \cf7 \strokec7 'Bookmarks'\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u12487 \u12501 \u12457 \u12523 \u12488 : Bookmarks\cf4 \cb1 \strokec4 \
\cb3 dynamodb \strokec6 =\strokec4  boto3.resource(\cf7 \strokec7 'dynamodb'\cf4 \strokec4 )\cb1 \
\cb3 bookmarks_table \strokec6 =\strokec4  dynamodb.Table(BOOKMARKS_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Received event: \cf8 \strokec8 \{\cf4 \strokec4 json.dumps(event)\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u12487 \u12496 \u12483 \u12464 \u29992 \u12395 \u12525 \u12464 \u20986 \u21147 \cf4 \cb1 \strokec4 \
\
\cb3     \cf5 \strokec5 try\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 # 1. \uc0\u12497 \u12473 \u12497 \u12521 \u12513 \u12540 \u12479 \u12363 \u12425  userId \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         path_params \strokec6 =\strokec4  event.get(\cf7 \strokec7 'pathParameters'\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  path_params \cf8 \strokec8 or\cf4 \strokec4  \cf7 \strokec7 'userId'\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  \cf8 \strokec8 in\cf4 \strokec4  path_params:\cb1 \
\cb3             \cf5 \strokec5 raise\cf4 \strokec4  \cf11 \strokec11 ValueError\cf4 \strokec4 (\cf7 \strokec7 "Missing 'userId' in path parameters"\cf4 \strokec4 )\cb1 \
\cb3         user_id \strokec6 =\strokec4  path_params[\cf7 \strokec7 'userId'\cf4 \strokec4 ]\cb1 \
\
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Fetching bookmarks for user: \cf8 \strokec8 \{\cf4 \strokec4 user_id\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 # 2. DynamoDB\uc0\u12398 Bookmarks\u12486 \u12540 \u12502 \u12523 \u12434 userId\u12391 \u12463 \u12456 \u12522 \cf4 \cb1 \strokec4 \
\cb3         response \strokec6 =\strokec4  bookmarks_table.query(\cb1 \
\cb3             \cf10 \strokec10 KeyConditionExpression\cf4 \strokec6 =\strokec4 Key(\cf7 \strokec7 'userId'\cf4 \strokec4 ).eq(user_id),\cb1 \
\cb3             \cf2 \strokec2 # \uc0\u21462 \u24471 \u12377 \u12427 \u23646 \u24615 \u12434 questionId\u12398 \u12415 \u12395 \u38480 \u23450  (\u21177 \u29575 \u21270 )\cf4 \cb1 \strokec4 \
\cb3             \cf10 \strokec10 ProjectionExpression\cf4 \strokec6 =\cf7 \strokec7 'questionId'\cf4 \cb1 \strokec4 \
\cb3         )\cb1 \
\
\cb3         \cf2 \strokec2 # 3. \uc0\u32080 \u26524 \u12363 \u12425 questionId\u12398 \u12522 \u12473 \u12488 \u12434 \u20316 \u25104 \cf4 \cb1 \strokec4 \
\cb3         items \strokec6 =\strokec4  response.get(\cf7 \strokec7 'Items'\cf4 \strokec4 , [])\cb1 \
\cb3         question_ids \strokec6 =\strokec4  [item[\cf7 \strokec7 'questionId'\cf4 \strokec4 ] \cf5 \strokec5 for\cf4 \strokec4  item \cf5 \strokec5 in\cf4 \strokec4  items]\cb1 \
\
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Found \cf8 \strokec8 \{\cf9 \strokec9 len\cf4 \strokec4 (question_ids)\cf8 \strokec8 \}\cf7 \strokec7  bookmarks."\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 # 4. \uc0\u25104 \u21151 \u12524 \u12473 \u12509 \u12531 \u12473  (200 OK)\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 # \uc0\u12450 \u12503 \u12522 \u20596 (ProfileViewModel)\u12398 \u24819 \u23450 \u12395 \u21512 \u12431 \u12379 \u12390 \u12461 \u12540 \u21517 \u12434 "bookmarks"\u12395 \u12377 \u12427 \cf4 \cb1 \strokec4 \
\cb3         response_body \strokec6 =\strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'bookmarks'\cf4 \strokec4 : question_ids\cb1 \
\cb3         \}\cb1 \
\
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(response_body),\cb1 \
\cb3             \cf7 \strokec7 'headers'\cf4 \strokec4 : \{\cf7 \strokec7 'Content-Type'\cf4 \strokec4 : \cf7 \strokec7 'application/json'\cf4 \strokec4 \}\cb1 \
\cb3         \}\cb1 \
\
\cb3     \cf5 \strokec5 except\cf4 \strokec4  ClientError \cf5 \strokec5 as\cf4 \strokec4  e:\cb1 \
\cb3         error_code \strokec6 =\strokec4  e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Code'\cf4 \strokec4 ]\cb1 \
\cb3         error_message \strokec6 =\strokec4  e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Message'\cf4 \strokec4 ]\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "DynamoDB Error: \cf8 \strokec8 \{\cf4 \strokec4 error_code\cf8 \strokec8 \}\cf7 \strokec7  - \cf8 \strokec8 \{\cf4 \strokec4 error_message\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 500\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf8 \strokec8 f\cf7 \strokec7 'Failed to fetch bookmarks due to database error: \cf8 \strokec8 \{\cf4 \strokec4 error_message\cf8 \strokec8 \}\cf7 \strokec7 '\cf4 \strokec4 \})\cb1 \
\cb3         \}\cb1 \
\cb3     \cf5 \strokec5 except\cf4 \strokec4  \cf11 \strokec11 ValueError\cf4 \strokec4  \cf5 \strokec5 as\cf4 \strokec4  ve:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Value Error: \cf8 \strokec8 \{\cf4 \strokec4 ve\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 400\cf4 \strokec4 , \cf2 \strokec2 # Bad Request\cf4 \cb1 \strokec4 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 (ve)\})\cb1 \
\cb3         \}\cb1 \
\cb3     \cf5 \strokec5 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf5 \strokec5 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Unexpected Error: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 500\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf8 \strokec8 f\cf7 \strokec7 'An unexpected error occurred: \cf8 \strokec8 \{\cf11 \strokec11 str\cf4 \strokec4 (e)\cf8 \strokec8 \}\cf7 \strokec7 '\cf4 \strokec4 \})\cb1 \
}