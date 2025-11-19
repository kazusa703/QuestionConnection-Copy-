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
\outl0\strokewidth0 \strokec2 # lambda_function.py for deleteQuestionFunction\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 import\cf4 \strokec4  json\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  boto3\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  os\cb1 \
\cf5 \cb3 \strokec5 from\cf4 \strokec4  botocore.exceptions \cf5 \strokec5 import\cf4 \strokec4  ClientError\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 # DynamoDB\uc0\u12486 \u12540 \u12502 \u12523 \u21517  (\u29872 \u22659 \u22793 \u25968 \u12363 \u12425 \u21462 \u24471 )\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 QUESTIONS_TABLE_NAME \strokec6 =\strokec4  os.environ.get(\cf7 \strokec7 'QUESTIONS_TABLE_NAME'\cf4 \strokec4 , \cf7 \strokec7 'Questions'\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u12487 \u12501 \u12457 \u12523 \u12488 : Questions\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 # (\uc0\u12458 \u12503 \u12471 \u12519 \u12531 ) \u12418 \u12375 \u38306 \u36899 \u12487 \u12540 \u12479 \u12434 \u21066 \u38500 \u12377 \u12427 \u22580 \u21512 \cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 # BOOKMARKS_TABLE_NAME = os.environ.get('BOOKMARKS_TABLE_NAME', 'Bookmarks')\cf4 \cb1 \strokec4 \
\cf2 \cb3 \strokec2 # ANSWERS_TABLE_NAME = os.environ.get('ANSWERS_TABLE_NAME', 'Answers')\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 dynamodb \strokec6 =\strokec4  boto3.resource(\cf7 \strokec7 'dynamodb'\cf4 \strokec4 )\cb1 \
\cb3 questions_table \strokec6 =\strokec4  dynamodb.Table(QUESTIONS_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Received event: \cf8 \strokec8 \{\cf4 \strokec4 json.dumps(event)\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u12487 \u12496 \u12483 \u12464 \u29992 \u12395 \u12525 \u12464 \u20986 \u21147 \cf4 \cb1 \strokec4 \
\
\cb3     \cf5 \strokec5 try\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 # 1. \uc0\u12497 \u12473 \u12497 \u12521 \u12513 \u12540 \u12479 \u12363 \u12425  questionId \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         path_params \strokec6 =\strokec4  event.get(\cf7 \strokec7 'pathParameters'\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  path_params \cf8 \strokec8 or\cf4 \strokec4  \cf7 \strokec7 'questionId'\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  \cf8 \strokec8 in\cf4 \strokec4  path_params:\cb1 \
\cb3             \cf5 \strokec5 raise\cf4 \strokec4  \cf11 \strokec11 ValueError\cf4 \strokec4 (\cf7 \strokec7 "Missing 'questionId' in path parameters"\cf4 \strokec4 )\cb1 \
\cb3         question_id \strokec6 =\strokec4  path_params[\cf7 \strokec7 'questionId'\cf4 \strokec4 ]\cb1 \
\
\cb3         \cf2 \strokec2 # 2. \uc0\u35469 \u35388 \u24773 \u22577 \u12363 \u12425 \u23455 \u34892 \u12518 \u12540 \u12470 \u12540 ID (sub) \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 # API Gateway Cognito\uc0\u12458 \u12540 \u12477 \u12521 \u12452 \u12470 \u12540 \u12363 \u12425 \u12398 \u24773 \u22577 \u12434 \u24819 \u23450 \cf4 \cb1 \strokec4 \
\cb3         request_context \strokec6 =\strokec4  event.get(\cf7 \strokec7 'requestContext'\cf4 \strokec4 , \{\})\cb1 \
\cb3         authorizer_context \strokec6 =\strokec4  request_context.get(\cf7 \strokec7 'authorizer'\cf4 \strokec4 , \{\})\cb1 \
\cb3         claims \strokec6 =\strokec4  authorizer_context.get(\cf7 \strokec7 'claims'\cf4 \strokec4 , \{\})\cb1 \
\cb3         requesting_user_id \strokec6 =\strokec4  claims.get(\cf7 \strokec7 'sub'\cf4 \strokec4 ) \cf2 \strokec2 # Cognito\uc0\u12398 'sub'\u12463 \u12524 \u12540 \u12512 \cf4 \cb1 \strokec4 \
\
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  requesting_user_id:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "ERROR: Could not extract user ID (sub) from authorizer claims."\cf4 \strokec4 )\cb1 \
\cb3             \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 403\cf4 \strokec4 , \cf2 \strokec2 # Forbidden (\uc0\u35469 \u35388 \u24773 \u22577 \u12364 \u12362 \u12363 \u12375 \u12356 )\cf4 \cb1 \strokec4 \
\cb3                 \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf7 \strokec7 'Could not verify user identity.'\cf4 \strokec4 \})\cb1 \
\cb3             \}\cb1 \
\
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Attempting delete for questionId: \cf8 \strokec8 \{\cf4 \strokec4 question_id\cf8 \strokec8 \}\cf7 \strokec7  by user: \cf8 \strokec8 \{\cf4 \strokec4 requesting_user_id\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 # 3. Questions\uc0\u12486 \u12540 \u12502 \u12523 \u12363 \u12425 \u36074 \u21839 \u24773 \u22577 \u12434 \u21462 \u24471 \u12375 \u12390 \u20316 \u25104 \u32773 \u12434 \u30906 \u35469 \cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 try\cf4 \strokec4 :\cb1 \
\cb3             response \strokec6 =\strokec4  questions_table.get_item(\cb1 \
\cb3                 \cf10 \strokec10 Key\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 'questionId'\cf4 \strokec4 : question_id\},\cb1 \
\cb3                 \cf10 \strokec10 ProjectionExpression\cf4 \strokec6 =\cf7 \strokec7 'authorId'\cf4 \strokec4  \cf2 \strokec2 # authorId\uc0\u12384 \u12369 \u21462 \u24471 \u12377 \u12428 \u12400 \u33391 \u12356 \cf4 \cb1 \strokec4 \
\cb3             )\cb1 \
\cb3         \cf5 \strokec5 except\cf4 \strokec4  ClientError \cf5 \strokec5 as\cf4 \strokec4  e:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "DynamoDB GetItem Error: \cf8 \strokec8 \{\cf4 \strokec4 e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Message'\cf4 \strokec4 ]\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cf5 \strokec5 raise\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Failed to get question details: \cf8 \strokec8 \{\cf4 \strokec4 e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Message'\cf4 \strokec4 ]\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u20877 \u35430 \u34892 \u19981 \u21487 \u33021 \u12394 \u12456 \u12521 \u12540 \u12392 \u12375 \u12390 \u25201 \u12358 \cf4 \cb1 \strokec4 \
\
\cb3         item \strokec6 =\strokec4  response.get(\cf7 \strokec7 'Item'\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  item:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "Question not found."\cf4 \strokec4 )\cb1 \
\cb3             \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 404\cf4 \strokec4 , \cf2 \strokec2 # Not Found\cf4 \cb1 \strokec4 \
\cb3                 \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf7 \strokec7 'Question not found'\cf4 \strokec4 \})\cb1 \
\cb3             \}\cb1 \
\
\cb3         author_id \strokec6 =\strokec4  item.get(\cf7 \strokec7 'authorId'\cf4 \strokec4 )\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Question authorId: \cf8 \strokec8 \{\cf4 \strokec4 author_id\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 # 4. \uc0\u20316 \u25104 \u32773 \u12392 \u23455 \u34892 \u12518 \u12540 \u12470 \u12540 \u12364 \u19968 \u33268 \u12377 \u12427 \u12363 \u26908 \u35388 \cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 if\cf4 \strokec4  author_id \strokec6 !=\strokec4  requesting_user_id:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "ERROR: User is not the author of the question."\cf4 \strokec4 )\cb1 \
\cb3             \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 403\cf4 \strokec4 , \cf2 \strokec2 # Forbidden (\uc0\u27177 \u38480 \u12394 \u12375 )\cf4 \cb1 \strokec4 \
\cb3                 \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf7 \strokec7 'You do not have permission to delete this question.'\cf4 \strokec4 \})\cb1 \
\cb3             \}\cb1 \
\
\cb3         \cf2 \strokec2 # 5. DynamoDB\uc0\u12363 \u12425 \u36074 \u21839 \u38917 \u30446 \u12434 \u21066 \u38500 \cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "User verified as author. Proceeding with deletion..."\cf4 \strokec4 )\cb1 \
\cb3         questions_table.delete_item(\cb1 \
\cb3             \cf10 \strokec10 Key\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 'questionId'\cf4 \strokec4 : question_id\}\cb1 \
\cb3             \cf2 \strokec2 # (\uc0\u12458 \u12503 \u12471 \u12519 \u12531 ) \u26465 \u20214 \u20184 \u12365 \u21066 \u38500 : \u12418 \u12375 \u21066 \u38500 \u30452 \u21069 \u12395 authorId\u12364 \u22793 \u12431 \u12387 \u12390 \u12356 \u12383 \u12425 \u22833 \u25943 \u12373 \u12379 \u12427 \cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 # ConditionExpression='attribute_exists(questionId) AND authorId = :uid',\cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 # ExpressionAttributeValues=\{':uid': requesting_user_id\}\cf4 \cb1 \strokec4 \
\cb3         )\cb1 \
\
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "Question deleted successfully from Questions table."\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 # --- (\uc0\u12458 \u12503 \u12471 \u12519 \u12531 ) \u38306 \u36899 \u12487 \u12540 \u12479 \u12398 \u12459 \u12473 \u12465 \u12540 \u12489 \u21066 \u38500  ---\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 # \cf8 \strokec8 TODO\cf2 \strokec2 : Bookmarks\uc0\u12486 \u12540 \u12502 \u12523 \u12420 Answers\u12486 \u12540 \u12502 \u12523 \u12363 \u12425 \u12289 \u12371 \u12398 questionId\u12395 \u38306 \u36899 \u12377 \u12427 \u38917 \u30446 \u12434 \u21066 \u38500 \u12377 \u12427 \u20966 \u29702 \u12434 \u36861 \u21152 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 # \uc0\u20363 : bookmarks_table.query(...) \u12391 \u21462 \u24471 \u12375 \u12390  delete_item \u12523 \u12540 \u12503 \u12394 \u12393 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 # -----------------------------------------------\cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 # 6. \uc0\u25104 \u21151 \u12524 \u12473 \u12509 \u12531 \u12473  (204 No Content)\cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 204\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : \cf7 \strokec7 ''\cf4 \cb1 \strokec4 \
\cb3         \}\cb1 \
\
\cb3     \cf5 \strokec5 except\cf4 \strokec4  \cf11 \strokec11 ValueError\cf4 \strokec4  \cf5 \strokec5 as\cf4 \strokec4  ve: \cf2 \strokec2 # \uc0\u12497 \u12521 \u12513 \u12540 \u12479 \u19981 \u36275 \u12394 \u12393 \cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Value Error: \cf8 \strokec8 \{\cf4 \strokec4 ve\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 400\cf4 \strokec4 , \cf2 \strokec2 # Bad Request\cf4 \cb1 \strokec4 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 (ve)\})\cb1 \
\cb3         \}\cb1 \
\cb3     \cf5 \strokec5 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf5 \strokec5 as\cf4 \strokec4  e: \cf2 \strokec2 # DynamoDB\uc0\u12456 \u12521 \u12540 \u21547 \u12416 \u12381 \u12398 \u20182 \u12398 \u20104 \u26399 \u12379 \u12396 \u12456 \u12521 \u12540 \cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Unexpected Error: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 500\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf8 \strokec8 f\cf7 \strokec7 'An unexpected error occurred: \cf8 \strokec8 \{\cf11 \strokec11 str\cf4 \strokec4 (e)\cf8 \strokec8 \}\cf7 \strokec7 '\cf4 \strokec4 \})\cb1 \
\cb3         \}\cb1 \
}