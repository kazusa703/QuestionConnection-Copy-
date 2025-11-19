{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red15\green112\blue1;\red0\green0\blue0;\red144\green1\blue18;\red0\green0\blue109;\red0\green0\blue255;
\red101\green76\blue29;\red32\green108\blue135;\red19\green118\blue70;\red230\green0\blue6;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c50196\c0;\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c6275\c50196;\cssrgb\c0\c0\c100000;
\cssrgb\c47451\c36863\c14902;\cssrgb\c14902\c49804\c60000;\cssrgb\c3529\c52549\c34510;\cssrgb\c93333\c0\c0;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  base64\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # AWS \uc0\u12463 \u12521 \u12452 \u12450 \u12531 \u12488 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 s3_client \strokec6 =\strokec4  boto3.client(\cf7 \strokec7 's3'\cf4 \strokec4 , \cf8 \strokec8 region_name\cf4 \strokec6 =\cf7 \strokec7 'ap-northeast-1'\cf4 \strokec4 )\cb1 \
\cb3 dynamodb \strokec6 =\strokec4  boto3.resource(\cf7 \strokec7 'dynamodb'\cf4 \strokec4 , \cf8 \strokec8 region_name\cf4 \strokec6 =\cf7 \strokec7 'ap-northeast-1'\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # \uc0\u35373 \u23450 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 S3_BUCKET_NAME \strokec6 =\strokec4  \cf7 \strokec7 'question-connection-profiles'\cf4 \cb1 \strokec4 \
\cb3 USERS_TABLE_NAME \strokec6 =\strokec4  \cf7 \strokec7 'Users'\cf4 \cb1 \strokec4 \
\cb3 AWS_REGION \strokec6 =\strokec4  \cf7 \strokec7 'ap-northeast-1'\cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # DynamoDB \uc0\u12486 \u12540 \u12502 \u12523 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 users_table \strokec6 =\strokec4  dynamodb.Table(USERS_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 def\cf4 \strokec4  \cf10 \strokec10 lambda_handler\cf4 \strokec4 (\cf8 \strokec8 event\cf4 \strokec4 , \cf8 \strokec8 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf7 \strokec7 """\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7     POST /users/\{userId\}/profileImage\cf4 \cb1 \strokec4 \
\cf7 \cb3 \strokec7     \uc0\u12510 \u12523 \u12481 \u12497 \u12540 \u12488 \u12501 \u12457 \u12540 \u12512 \u12487 \u12540 \u12479 \u12391 \u21463 \u12369 \u21462 \u12387 \u12383 \u30011 \u20687 \u12434 S3\u12395 \u12450 \u12483 \u12503 \u12525 \u12540 \u12489 \cf4 \cb1 \strokec4 \
\cf7 \cb3 \strokec7     """\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[START] uploadProfileImage"\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12497 \u12473 \u12497 \u12521 \u12513 \u12540 \u12479 \u12363 \u12425  userId \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         user_id \strokec6 =\strokec4  event[\cf7 \strokec7 'pathParameters'\cf4 \strokec4 ][\cf7 \strokec7 'userId'\cf4 \strokec4 ]\cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] userId: \cf9 \strokec9 \{\cf4 \strokec4 user_id\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12508 \u12487 \u12451 \u12363 \u12425 \u30011 \u20687 \u12487 \u12540 \u12479 \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         body \strokec6 =\strokec4  event.get(\cf7 \strokec7 'body'\cf4 \strokec4 , \cf7 \strokec7 ''\cf4 \strokec4 )\cb1 \
\cb3         is_base64 \strokec6 =\strokec4  event.get(\cf7 \strokec7 'isBase64Encoded'\cf4 \strokec4 , \cf9 \strokec9 False\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] isBase64Encoded: \cf9 \strokec9 \{\cf4 \strokec4 is_base64\cf9 \strokec9 \}\cf7 \strokec7 , body length: \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (body)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  is_base64:\cb1 \
\cb3             image_data \strokec6 =\strokec4  base64.b64decode(body)\cb1 \
\cb3         \cf2 \strokec2 else\cf4 \strokec4 :\cb1 \
\cb3             image_data \strokec6 =\strokec4  body.encode(\cf7 \strokec7 'utf-8'\cf4 \strokec4 ) \cf2 \strokec2 if\cf4 \strokec4  \cf10 \strokec10 isinstance\cf4 \strokec4 (body, \cf11 \strokec11 str\cf4 \strokec4 ) \cf2 \strokec2 else\cf4 \strokec4  body\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] image_data length: \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (image_data)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12510 \u12523 \u12481 \u12497 \u12540 \u12488 \u12501 \u12457 \u12540 \u12512 \u12487 \u12540 \u12479 \u12398 \u12497 \u12540 \u12473 \cf4 \cb1 \strokec4 \
\cb3         content_type \strokec6 =\strokec4  event.get(\cf7 \strokec7 'headers'\cf4 \strokec4 , \{\}).get(\cf7 \strokec7 'content-type'\cf4 \strokec4 , \cf7 \strokec7 ''\cf4 \strokec4 )\cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] content_type: \cf9 \strokec9 \{\cf4 \strokec4 content_type\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 'boundary='\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  \cf9 \strokec9 in\cf4 \strokec4  content_type:\cb1 \
\cb3             \cf10 \strokec10 print\cf4 \strokec4 (\cf7 \strokec7 "[ERROR] Invalid Content-Type"\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 400\cf4 \strokec4 ,\cb1 \
\cb3                 \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf7 \strokec7 'Invalid Content-Type'\cf4 \strokec4 \}),\cb1 \
\cb3                 \cf7 \strokec7 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3                     \cf7 \strokec7 'Content-Type'\cf4 \strokec4 : \cf7 \strokec7 'application/json'\cf4 \strokec4 ,\cb1 \
\cb3                     \cf7 \strokec7 'Access-Control-Allow-Origin'\cf4 \strokec4 : \cf7 \strokec7 '*'\cf4 \cb1 \strokec4 \
\cb3                 \}\cb1 \
\cb3             \}\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # boundary \uc0\u12434 \u25277 \u20986 \cf4 \cb1 \strokec4 \
\cb3         boundary \strokec6 =\strokec4  content_type.split(\cf7 \strokec7 'boundary='\cf4 \strokec4 )[\cf12 \strokec12 1\cf4 \strokec4 ].split(\cf7 \strokec7 ';'\cf4 \strokec4 )[\cf12 \strokec12 0\cf4 \strokec4 ]\cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] boundary: \cf9 \strokec9 \{\cf4 \strokec4 boundary\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12510 \u12523 \u12481 \u12497 \u12540 \u12488 \u12487 \u12540 \u12479 \u12363 \u12425 \u30011 \u20687 \u12434 \u25277 \u20986 \cf4 \cb1 \strokec4 \
\cb3         image_bytes \strokec6 =\strokec4  extract_image_from_multipart(image_data, boundary)\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  image_bytes:\cb1 \
\cb3             \cf10 \strokec10 print\cf4 \strokec4 (\cf7 \strokec7 "[ERROR] No image data found"\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 400\cf4 \strokec4 ,\cb1 \
\cb3                 \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf7 \strokec7 'No image data found'\cf4 \strokec4 \}),\cb1 \
\cb3                 \cf7 \strokec7 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3                     \cf7 \strokec7 'Content-Type'\cf4 \strokec4 : \cf7 \strokec7 'application/json'\cf4 \strokec4 ,\cb1 \
\cb3                     \cf7 \strokec7 'Access-Control-Allow-Origin'\cf4 \strokec4 : \cf7 \strokec7 '*'\cf4 \cb1 \strokec4 \
\cb3                 \}\cb1 \
\cb3             \}\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] extracted image size: \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (image_bytes)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # S3 \uc0\u12395 \u12450 \u12483 \u12503 \u12525 \u12540 \u12489 \cf4 \cb1 \strokec4 \
\cb3         s3_key \strokec6 =\strokec4  \cf9 \strokec9 f\cf7 \strokec7 "profile-images/\cf9 \strokec9 \{\cf4 \strokec4 user_id\cf9 \strokec9 \}\cf7 \strokec7 /profile.jpg"\cf4 \cb1 \strokec4 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] uploading to S3: \cf9 \strokec9 \{\cf4 \strokec4 s3_key\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # \uc0\u9733 \u9733 \u9733  \u20462 \u27491 \u65306 ACL \u12497 \u12521 \u12513 \u12540 \u12479 \u12434 \u21066 \u38500  \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\cb3         s3_client.put_object(\cb1 \
\cb3             \cf8 \strokec8 Bucket\cf4 \strokec6 =\strokec4 S3_BUCKET_NAME,\cb1 \
\cb3             \cf8 \strokec8 Key\cf4 \strokec6 =\strokec4 s3_key,\cb1 \
\cb3             \cf8 \strokec8 Body\cf4 \strokec6 =\strokec4 image_bytes,\cb1 \
\cb3             \cf8 \strokec8 ContentType\cf4 \strokec6 =\cf7 \strokec7 'image/jpeg'\cf4 \cb1 \strokec4 \
\cb3         )\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] S3 upload success: \cf9 \strokec9 \{\cf4 \strokec4 s3_key\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # S3 \uc0\u30011 \u20687  URL \u12434 \u29983 \u25104 \cf4 \cb1 \strokec4 \
\cb3         image_url \strokec6 =\strokec4  \cf9 \strokec9 f\cf7 \strokec7 "https://\cf9 \strokec9 \{\cf4 \strokec4 S3_BUCKET_NAME\cf9 \strokec9 \}\cf7 \strokec7 .s3.\cf9 \strokec9 \{\cf4 \strokec4 AWS_REGION\cf9 \strokec9 \}\cf7 \strokec7 .amazonaws.com/\cf9 \strokec9 \{\cf4 \strokec4 s3_key\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \cb1 \strokec4 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] image_url: \cf9 \strokec9 \{\cf4 \strokec4 image_url\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # DynamoDB \uc0\u12395  profileImageUrl \u12434 \u20445 \u23384 \cf4 \cb1 \strokec4 \
\cb3         users_table.update_item(\cb1 \
\cb3             \cf8 \strokec8 Key\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 'userId'\cf4 \strokec4 : user_id\},\cb1 \
\cb3             \cf8 \strokec8 UpdateExpression\cf4 \strokec6 =\cf7 \strokec7 'SET profileImageUrl = :url'\cf4 \strokec4 ,\cb1 \
\cb3             \cf8 \strokec8 ExpressionAttributeValues\cf4 \strokec6 =\strokec4 \{\cb1 \
\cb3                 \cf7 \strokec7 ':url'\cf4 \strokec4 : image_url\cb1 \
\cb3             \}\cb1 \
\cb3         )\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[INFO] DynamoDB update success"\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         response \strokec6 =\strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cb1 \
\cb3                 \cf7 \strokec7 'profileImageUrl'\cf4 \strokec4 : image_url,\cb1 \
\cb3                 \cf7 \strokec7 'message'\cf4 \strokec4 : \cf7 \strokec7 'Profile image uploaded successfully'\cf4 \cb1 \strokec4 \
\cb3             \}),\cb1 \
\cb3             \cf7 \strokec7 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3                 \cf7 \strokec7 'Content-Type'\cf4 \strokec4 : \cf7 \strokec7 'application/json'\cf4 \strokec4 ,\cb1 \
\cb3                 \cf7 \strokec7 'Access-Control-Allow-Origin'\cf4 \strokec4 : \cf7 \strokec7 '*'\cf4 \cb1 \strokec4 \
\cb3             \}\cb1 \
\cb3         \}\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[SUCCESS] uploadProfileImage completed"\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  response\cb1 \
\cb3     \cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[ERROR] Exception: \cf9 \strokec9 \{\cf11 \strokec11 str\cf4 \strokec4 (e)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 import\cf4 \strokec4  traceback\cb1 \
\cb3         traceback.print_exc()\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf7 \strokec7 'statusCode'\cf4 \strokec4 : \cf12 \strokec12 500\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(\{\cf7 \strokec7 'error'\cf4 \strokec4 : \cf11 \strokec11 str\cf4 \strokec4 (e)\}),\cb1 \
\cb3             \cf7 \strokec7 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3                 \cf7 \strokec7 'Content-Type'\cf4 \strokec4 : \cf7 \strokec7 'application/json'\cf4 \strokec4 ,\cb1 \
\cb3                 \cf7 \strokec7 'Access-Control-Allow-Origin'\cf4 \strokec4 : \cf7 \strokec7 '*'\cf4 \cb1 \strokec4 \
\cb3             \}\cb1 \
\cb3         \}\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 def\cf4 \strokec4  \cf10 \strokec10 extract_image_from_multipart\cf4 \strokec4 (\cf8 \strokec8 data\cf4 \strokec4 , \cf8 \strokec8 boundary\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf7 \strokec7 """\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7     \uc0\u12510 \u12523 \u12481 \u12497 \u12540 \u12488 \u12501 \u12457 \u12540 \u12512 \u12487 \u12540 \u12479 \u12363 \u12425 \u30011 \u20687 \u12496 \u12452 \u12490 \u12522 \u12434 \u25277 \u20986 \cf4 \cb1 \strokec4 \
\cf7 \cb3 \strokec7     """\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[extract_image_from_multipart] data length: \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (data)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         boundary_bytes \strokec6 =\strokec4  boundary.encode(\cf7 \strokec7 'utf-8'\cf4 \strokec4 )\cb1 \
\cb3         parts \strokec6 =\strokec4  data.split(\cf9 \strokec9 b\cf7 \strokec7 '--'\cf4 \strokec4  \strokec6 +\strokec4  boundary_bytes)\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[extract_image_from_multipart] parts count: \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (parts)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 for\cf4 \strokec4  i, part \cf2 \strokec2 in\cf4 \strokec4  \cf10 \strokec10 enumerate\cf4 \strokec4 (parts):\cb1 \
\cb3             \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[extract_image_from_multipart] checking part \cf9 \strokec9 \{\cf4 \strokec4 i\cf9 \strokec9 \}\cf7 \strokec7 , length: \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (part)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 b\cf7 \strokec7 'Content-Disposition: form-data'\cf4 \strokec4  \cf9 \strokec9 in\cf4 \strokec4  part \cf9 \strokec9 and\cf4 \strokec4  \cf9 \strokec9 b\cf7 \strokec7 'profileImage'\cf4 \strokec4  \cf9 \strokec9 in\cf4 \strokec4  part:\cb1 \
\cb3                 \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[extract_image_from_multipart] found profileImage in part \cf9 \strokec9 \{\cf4 \strokec4 i\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3                 \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 b\cf7 \strokec7 '\cf13 \strokec13 \\r\\n\\r\\n\cf7 \strokec7 '\cf4 \strokec4  \cf9 \strokec9 in\cf4 \strokec4  part:\cb1 \
\cb3                     _, body \strokec6 =\strokec4  part.split(\cf9 \strokec9 b\cf7 \strokec7 '\cf13 \strokec13 \\r\\n\\r\\n\cf7 \strokec7 '\cf4 \strokec4 , \cf12 \strokec12 1\cf4 \strokec4 )\cb1 \
\cb3                     body \strokec6 =\strokec4  body.rstrip(\cf9 \strokec9 b\cf7 \strokec7 '\cf13 \strokec13 \\r\\n\cf7 \strokec7 '\cf4 \strokec4 )\cb1 \
\cb3                     \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[extract_image_from_multipart] extracted body length: \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (body)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3                     \cf2 \strokec2 return\cf4 \strokec4  body\cb1 \
\cb3         \cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf7 \strokec7 "[extract_image_from_multipart] profileImage not found"\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf9 \strokec9 None\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf11 \strokec11 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf10 \strokec10 print\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "[extract_image_from_multipart] Error: \cf9 \strokec9 \{\cf11 \strokec11 str\cf4 \strokec4 (e)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 import\cf4 \strokec4  traceback\cb1 \
\cb3         traceback.print_exc()\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf9 \strokec9 None\cf4 \cb1 \strokec4 \
}