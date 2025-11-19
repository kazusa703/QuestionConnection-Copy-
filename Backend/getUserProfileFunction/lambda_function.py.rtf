{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red0\green0\blue255;\red32\green108\blue135;\red101\green76\blue29;\red0\green0\blue109;\red0\green0\blue0;
\red19\green118\blue70;\red144\green1\blue18;\red15\green112\blue1;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c0\c100000;\cssrgb\c14902\c49804\c60000;\cssrgb\c47451\c36863\c14902;\cssrgb\c0\c6275\c50196;\cssrgb\c0\c0\c0;
\cssrgb\c3529\c52549\c34510;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c50196\c0;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  decimal \cf2 \strokec2 import\cf4 \strokec4  Decimal\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 class\cf4 \strokec4  \cf6 \strokec6 DecimalEncoder\cf4 \strokec4 (\cf6 \strokec6 json\cf4 \strokec4 .\cf6 \strokec6 JSONEncoder\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf5 \strokec5 def\cf4 \strokec4  \cf7 \strokec7 default\cf4 \strokec4 (\cf8 \strokec8 self\cf4 \strokec4 , \cf8 \strokec8 o\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 isinstance\cf4 \strokec4 (o, Decimal):\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \cf6 \strokec6 int\cf4 \strokec4 (o) \cf2 \strokec2 if\cf4 \strokec4  o \strokec9 %\strokec4  \cf10 \strokec10 1\cf4 \strokec4  \strokec9 ==\strokec4  \cf10 \strokec10 0\cf4 \strokec4  \cf2 \strokec2 else\cf4 \strokec4  \cf6 \strokec6 float\cf4 \strokec4 (o)\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf6 \strokec6 super\cf4 \strokec4 (DecimalEncoder, \cf5 \strokec5 self\cf4 \strokec4 ).default(o)\cb1 \
\
\cb3 dynamodb \strokec9 =\strokec4  boto3.resource(\cf11 \strokec11 'dynamodb'\cf4 \strokec4 )\cb1 \
\pard\pardeftab720\partightenfactor0
\cf12 \cb3 \strokec12 # DynamoDB\uc0\u12398 \u12486 \u12540 \u12502 \u12523 \u21517 \u12434  Users \u12395 \u20462 \u27491  (\u12473 \u12463 \u12522 \u12540 \u12531 \u12471 \u12519 \u12483 \u12488  2025-11-12 13.36.58.png \u12424 \u12426 )\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 table \strokec9 =\strokec4  dynamodb.Table(\cf11 \strokec11 'Users'\cf4 \strokec4 ) \cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 def\cf4 \strokec4  \cf7 \strokec7 lambda_handler\cf4 \strokec4 (\cf8 \strokec8 event\cf4 \strokec4 , \cf8 \strokec8 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "Received event: \cf5 \strokec5 \{\cf4 \strokec4 json.dumps(event)\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 ) \cb1 \
\
\cb3         path_params \strokec9 =\strokec4  event.get(\cf11 \strokec11 'pathParameters'\cf4 \strokec4 , \{\})\cb1 \
\cb3         user_id \strokec9 =\strokec4  path_params.get(\cf11 \strokec11 'userId'\cf4 \strokec4 )\cb1 \
\
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "Extracted userId: \cf5 \strokec5 \{\cf4 \strokec4 user_id\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf5 \strokec5 not\cf4 \strokec4  user_id:\cb1 \
\cb3             \cf7 \strokec7 print\cf4 \strokec4 (\cf11 \strokec11 "Error: userId is missing."\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 400\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 'headers'\cf4 \strokec4 : \{ \cf11 \strokec11 'Content-Type'\cf4 \strokec4 : \cf11 \strokec11 'application/json'\cf4 \strokec4  \},\cb1 \
\cb3                 \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 'error'\cf4 \strokec4 : \cf11 \strokec11 'userId is required'\cf4 \strokec4 \})\cb1 \
\cb3             \}\cb1 \
\
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "Attempting to get item for userId: \cf5 \strokec5 \{\cf4 \strokec4 user_id\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\
\cb3         response \strokec9 =\strokec4  table.get_item(\cb1 \
\cb3             \cf8 \strokec8 Key\cf4 \strokec9 =\strokec4 \{\cf11 \strokec11 'userId'\cf4 \strokec4 : user_id\},\cb1 \
\cb3             \cf12 \strokec12 # \uc0\u9733 \u9733 \u9733  1. \u21462 \u24471 \u12377 \u12427 \u23646 \u24615 \u12434 \u38480 \u23450  (deviceToken\u12394 \u12393 \u19981 \u35201 \u12394 \u24773 \u22577 \u12434 \u38500 \u22806 ) \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\cb3             \cf8 \strokec8 ProjectionExpression\cf4 \strokec9 =\cf11 \strokec11 "nickname, notifyOnCorrectAnswer, notifyOnDM"\cf4 \cb1 \strokec4 \
\cb3         )\cb1 \
\
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "DynamoDB get_item response: \cf5 \strokec5 \{\cf4 \strokec4 json.dumps(response, \cf8 \strokec8 cls\cf4 \strokec9 =\strokec4 DecimalEncoder)\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\
\cb3         item \strokec9 =\strokec4  response.get(\cf11 \strokec11 'Item'\cf4 \strokec4 )\cb1 \
\
\cb3         \cf12 \strokec12 # \uc0\u9733 \u9733 \u9733  2. \u12524 \u12473 \u12509 \u12531 \u12473 \u12398 \u24418 \u24335 \u12434 \u12450 \u12503 \u12522  (UserProfile \u27083 \u36896 \u20307 ) \u12395 \u21512 \u12431 \u12379 \u12427  \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf5 \strokec5 not\cf4 \strokec4  item:\cb1 \
\cb3             \cf12 \strokec12 # \uc0\u12518 \u12540 \u12470 \u12540 \u12399 \u23384 \u22312 \u12377 \u12427 \u12364 \u12289 \u12414 \u12384 \u12503 \u12525 \u12501 \u12449 \u12452 \u12523 \u24773 \u22577 \u12364 \u12394 \u12356 \u22580 \u21512 \cf4 \cb1 \strokec4 \
\cb3             \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "Item not found for userId: \cf5 \strokec5 \{\cf4 \strokec4 user_id\cf5 \strokec5 \}\cf11 \strokec11 . Returning default profile."\cf4 \strokec4 )\cb1 \
\cb3             response_body \strokec9 =\strokec4  \{\cb1 \
\cb3                 \cf11 \strokec11 'nickname'\cf4 \strokec4 : \cf5 \strokec5 None\cf4 \strokec4 , \cf12 \strokec12 # \uc0\u12414 \u12383 \u12399  ''\cf4 \cb1 \strokec4 \
\cb3                 \cf11 \strokec11 'notifyOnCorrectAnswer'\cf4 \strokec4 : \cf5 \strokec5 False\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 'notifyOnDM'\cf4 \strokec4 : \cf5 \strokec5 False\cf4 \cb1 \strokec4 \
\cb3             \}\cb1 \
\cb3         \cf2 \strokec2 else\cf4 \strokec4 :\cb1 \
\cb3             \cf12 \strokec12 # \uc0\u12518 \u12540 \u12470 \u12540 \u24773 \u22577 \u12364 \u23384 \u22312 \u12377 \u12427 \u22580 \u21512 \cf4 \cb1 \strokec4 \
\cb3             \cf12 \strokec12 # DB\uc0\u12395 \u12461 \u12540 \u12364 \u23384 \u22312 \u12375 \u12394 \u12356  (None) \u22580 \u21512 \u12399  False \u12434 \u35373 \u23450 \u12377 \u12427 \cf4 \cb1 \strokec4 \
\cb3             response_body \strokec9 =\strokec4  \{\cb1 \
\cb3                 \cf11 \strokec11 'nickname'\cf4 \strokec4 : item.get(\cf11 \strokec11 'nickname'\cf4 \strokec4 ),\cb1 \
\cb3                 \cf11 \strokec11 'notifyOnCorrectAnswer'\cf4 \strokec4 : item.get(\cf11 \strokec11 'notifyOnCorrectAnswer'\cf4 \strokec4 , \cf5 \strokec5 False\cf4 \strokec4 ),\cb1 \
\cb3                 \cf11 \strokec11 'notifyOnDM'\cf4 \strokec4 : item.get(\cf11 \strokec11 'notifyOnDM'\cf4 \strokec4 , \cf5 \strokec5 False\cf4 \strokec4 )\cb1 \
\cb3             \}\cb1 \
\cb3             \cb1 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "Returning profile: \cf5 \strokec5 \{\cf4 \strokec4 json.dumps(response_body, \cf8 \strokec8 cls\cf4 \strokec9 =\strokec4 DecimalEncoder)\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf11 \strokec11 'headers'\cf4 \strokec4 : \{ \cf11 \strokec11 'Content-Type'\cf4 \strokec4 : \cf11 \strokec11 'application/json'\cf4 \strokec4  \},\cb1 \
\cb3             \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(response_body, \cf8 \strokec8 cls\cf4 \strokec9 =\strokec4 DecimalEncoder)\cb1 \
\cb3         \}\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf6 \strokec6 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "An exception occurred: \cf5 \strokec5 \{\cf4 \strokec4 e\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 ) \cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 500\cf4 \strokec4 ,\cb1 \
\cb3             \cf11 \strokec11 'headers'\cf4 \strokec4 : \{ \cf11 \strokec11 'Content-Type'\cf4 \strokec4 : \cf11 \strokec11 'application/json'\cf4 \strokec4  \},\cb1 \
\cb3             \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 'error'\cf4 \strokec4 : \cf6 \strokec6 str\cf4 \strokec4 (e)\})\cb1 \
\cb3         \}\cb1 \
}