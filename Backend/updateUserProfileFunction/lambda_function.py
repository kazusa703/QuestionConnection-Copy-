{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red15\green112\blue1;\red255\green255\blue255;\red45\green45\blue45;
\red157\green0\blue210;\red0\green0\blue0;\red144\green1\blue18;\red0\green0\blue255;\red101\green76\blue29;
\red0\green0\blue109;\red19\green118\blue70;\red32\green108\blue135;}
{\*\expandedcolortbl;;\cssrgb\c0\c50196\c0;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c68627\c0\c85882;\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c0\c100000;\cssrgb\c47451\c36863\c14902;
\cssrgb\c0\c6275\c50196;\cssrgb\c3529\c52549\c34510;\cssrgb\c14902\c49804\c60000;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 # test\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 import\cf4 \strokec4  json\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  boto3\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  time\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 dynamodb \strokec6 =\strokec4  boto3.resource(\cf7 \strokec7 'dynamodb'\cf4 \strokec4 )\cb1 \
\cb3 table \strokec6 =\strokec4  dynamodb.Table(\cf7 \strokec7 'Users'\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf5 \strokec5 try\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Received event: \cf8 \strokec8 \{\cf4 \strokec4 json.dumps(event)\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 ) \cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 # 1. \uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12497 \u12473 \u12363 \u12425  userId \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         path_params \strokec6 =\strokec4  event.get(\cf7 \strokec7 'pathParameters'\cf4 \strokec4 , \{\})\cb1 \
\cb3         user_id \strokec6 =\strokec4  path_params.get(\cf7 \strokec7 'userId'\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Extracted userId: \cf8 \strokec8 \{\cf4 \strokec4 user_id\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 # 2. \uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u26412 \u25991  (body) \u12363 \u12425  nickname \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         body_str \strokec6 =\strokec4  event.get(\cf7 \strokec7 'body'\cf4 \strokec4 , \cf7 \strokec7 '\cf8 \strokec8 \{\}\cf7 \strokec7 '\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Received body string: \cf8 \strokec8 \{\cf4 \strokec4 body_str\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         body \strokec6 =\strokec4  json.loads(body_str)\cb1 \
\cb3         nickname \strokec6 =\strokec4  body.get(\cf7 \strokec7 'nickname'\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Extracted nickname: \cf8 \strokec8 \{\cf4 \strokec4 nickname\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\
\cb3         \cf2 \strokec2 # 3. \uc0\u24517 \u38920 \u12497 \u12521 \u12513 \u12540 \u12479 \u12398 \u12481 \u12455 \u12483 \u12463 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u20462 \u27491 : nickname\u12364 \u31354 \u25991 \u23383  "" \u12398 \u22580 \u21512 \u12418 \u35377 \u21487 \u12377 \u12427  \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  user_id \cf8 \strokec8 or\cf4 \strokec4  nickname \cf8 \strokec8 is\cf4 \strokec4  \cf8 \strokec8 None\cf4 \strokec4 : \cf2 \strokec2 # nickname\uc0\u12364 None\u12398 \u22580 \u21512 \u12398 \u12415 \u12456 \u12521 \u12540 \u12392 \u12377 \u12427 \cf4 \cb1 \strokec4 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "Error: userId or nickname is missing or invalid."\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u9733  \u12525 \u12464 \u36861 \u21152 \cf4 \cb1 \strokec4 \
\cb3             \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 400\cf4 \strokec4 ,\cb1 \
\cb3                 \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf7 \strokec7 'userId and nickname (even if empty) are required'\cf4 \strokec4 \})\cb1 \
\cb3             \}\cb1 \
\
\cb3         \cf2 \strokec2 # 4. \uc0\u35469 \u35388 \u12373 \u12428 \u12383 \u12518 \u12540 \u12470 \u12540 \u12364 \u33258 \u20998 \u12398 \u24773 \u22577 \u12398 \u12415 \u26356 \u26032 \u12391 \u12365 \u12427 \u12424 \u12358 \u12395 \u12481 \u12455 \u12483 \u12463 \cf4 \cb1 \strokec4 \
\cb3         auth_sub \strokec6 =\strokec4  \cf8 \strokec8 None\cf4 \strokec4  \cf2 \strokec2 # \uc0\u9733  \u21021 \u26399 \u21270 \cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 try\cf4 \strokec4 :\cb1 \
\cb3             auth_sub \strokec6 =\strokec4  event[\cf7 \strokec7 'requestContext'\cf4 \strokec4 ][\cf7 \strokec7 'authorizer'\cf4 \strokec4 ][\cf7 \strokec7 'claims'\cf4 \strokec4 ][\cf7 \strokec7 'sub'\cf4 \strokec4 ]\cb1 \
\cb3             \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Cognito authorizer sub: \cf8 \strokec8 \{\cf4 \strokec4 auth_sub\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cf5 \strokec5 if\cf4 \strokec4  auth_sub \strokec6 !=\strokec4  user_id:\cb1 \
\cb3                 \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Forbidden: auth_sub (\cf8 \strokec8 \{\cf4 \strokec4 auth_sub\cf8 \strokec8 \}\cf7 \strokec7 ) does not match userId (\cf8 \strokec8 \{\cf4 \strokec4 user_id\cf8 \strokec8 \}\cf7 \strokec7 )"\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u9733  \u12525 \u12464 \u36861 \u21152 \cf4 \cb1 \strokec4 \
\cb3                 \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3                     \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 403\cf4 \strokec4 ,\cb1 \
\cb3                     \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf7 \strokec7 'Forbidden: You can only update your own profile.'\cf4 \strokec4 \})\cb1 \
\cb3                 \}\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "Authorization check passed."\cf4 \strokec4 ) \cf2 \strokec2 # \uc0\u9733  \u12525 \u12464 \u36861 \u21152 \cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 except\cf4 \strokec4  \cf12 \strokec12 KeyError\cf4 \strokec4 :\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "Warning: Cognito authorizer claims not found. Skipping auth check."\cf4 \strokec4 )\cb1 \
\
\
\cb3         \cf2 \strokec2 # 5. DynamoDB Users\uc0\u12486 \u12540 \u12502 \u12523 \u12395 \u12487 \u12540 \u12479 \u12434 \u20445 \u23384 \u65288 \u26356 \u26032 \u12414 \u12383 \u12399 \u26032 \u35215 \u20316 \u25104 \u65289 \cf4 \cb1 \strokec4 \
\cb3         item_to_save \strokec6 =\strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'userId'\cf4 \strokec4 : user_id,       \cf2 \strokec2 # \uc0\u12497 \u12540 \u12486 \u12451 \u12471 \u12519 \u12531 \u12461 \u12540 \cf4 \cb1 \strokec4 \
\cb3             \cf7 \strokec7 'nickname'\cf4 \strokec4 : nickname,    \cf2 \strokec2 # nickname\uc0\u12364 \u31354 \u25991 \u23383  "" \u12398 \u22580 \u21512 \u12418 \u12381 \u12398 \u12414 \u12414 \u20445 \u23384 \cf4 \cb1 \strokec4 \
\cb3             \cf7 \strokec7 'updatedAt'\cf4 \strokec4 : \cf12 \strokec12 int\cf4 \strokec4 (time.time())\cb1 \
\cb3         \}\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "Attempting to put item: \cf8 \strokec8 \{\cf4 \strokec4 json.dumps(item_to_save)\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         table.put_item(\cf10 \strokec10 Item\cf4 \strokec6 =\strokec4 item_to_save)\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 "Successfully put item to DynamoDB."\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'message'\cf4 \strokec4 : \cf7 \strokec7 'Profile updated successfully'\cf4 \strokec4 \})\cb1 \
\cb3         \}\cb1 \
\
\cb3     \cf5 \strokec5 except\cf4 \strokec4  \cf12 \strokec12 Exception\cf4 \strokec4  \cf5 \strokec5 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf2 \strokec2 # --- \uc0\u9733 \u9733 \u9733  \u12525 \u12464 \u36861 \u21152  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf7 \strokec7 "An exception occurred: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf7 \strokec7 "\cf4 \strokec4 ) \cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 500\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf12 \strokec12 str\cf4 \strokec4 (e)\})\cb1 \
\cb3         \}\cb1 \
}