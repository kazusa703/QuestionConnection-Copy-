{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red15\green112\blue1;\red0\green0\blue255;\red32\green108\blue135;\red101\green76\blue29;\red0\green0\blue109;
\red0\green0\blue0;\red19\green118\blue70;\red144\green1\blue18;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c50196\c0;\cssrgb\c0\c0\c100000;\cssrgb\c14902\c49804\c60000;\cssrgb\c47451\c36863\c14902;\cssrgb\c0\c6275\c50196;
\cssrgb\c0\c0\c0;\cssrgb\c3529\c52549\c34510;\cssrgb\c63922\c8235\c8235;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  decimal \cf2 \strokec2 import\cf4 \strokec4  Decimal\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  boto3.dynamodb.conditions \cf2 \strokec2 import\cf4 \strokec4  Key, Attr \cf5 \strokec5 # GSI\uc0\u12434 \u20351 \u12358 \u22580 \u21512 \u12399 Key\u12418 \u24517 \u35201 \u12395 \u12394 \u12427 \u21487 \u33021 \u24615 \cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 class\cf4 \strokec4  \cf7 \strokec7 DecimalEncoder\cf4 \strokec4 (\cf7 \strokec7 json\cf4 \strokec4 .\cf7 \strokec7 JSONEncoder\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf6 \strokec6 def\cf4 \strokec4  \cf8 \strokec8 default\cf4 \strokec4 (\cf9 \strokec9 self\cf4 \strokec4 , \cf9 \strokec9 o\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 isinstance\cf4 \strokec4 (o, Decimal):\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \cf7 \strokec7 int\cf4 \strokec4 (o) \cf2 \strokec2 if\cf4 \strokec4  o \strokec10 %\strokec4  \cf11 \strokec11 1\cf4 \strokec4  \strokec10 ==\strokec4  \cf11 \strokec11 0\cf4 \strokec4  \cf2 \strokec2 else\cf4 \strokec4  \cf7 \strokec7 float\cf4 \strokec4 (o)\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf7 \strokec7 super\cf4 \strokec4 (DecimalEncoder, \cf6 \strokec6 self\cf4 \strokec4 ).default(o)\cb1 \
\
\cb3 dynamodb \strokec10 =\strokec4  boto3.resource(\cf12 \strokec12 'dynamodb'\cf4 \strokec4 )\cb1 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # AnswersLog\uc0\u12486 \u12540 \u12502 \u12523 \u12398 UserIndex GSI\u12434 \u20351 \u29992 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 table \strokec10 =\strokec4  dynamodb.Table(\cf12 \strokec12 'AnswersLog'\cf4 \strokec4 )\cb1 \
\cb3 user_index_name \strokec10 =\strokec4  \cf12 \strokec12 'UserIndex'\cf4 \strokec4  \cf5 \strokec5 # GSI\uc0\u21517 \u12434 \u23450 \u32681 \cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 def\cf4 \strokec4  \cf8 \strokec8 lambda_handler\cf4 \strokec4 (\cf9 \strokec9 event\cf4 \strokec4 , \cf9 \strokec9 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         user_id \strokec10 =\strokec4  event[\cf12 \strokec12 'pathParameters'\cf4 \strokec4 ][\cf12 \strokec12 'userId'\cf4 \strokec4 ]\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf6 \strokec6 not\cf4 \strokec4  user_id:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 400\cf4 \strokec4 , \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(\{\cf12 \strokec12 'error'\cf4 \strokec4 : \cf12 \strokec12 'userId is required'\cf4 \strokec4 \})\}\cb1 \
\
\cb3         \cf5 \strokec5 # UserIndex GSI\uc0\u12395 \u23550 \u12375 \u12390 \u12463 \u12456 \u12522 \u12434 \u23455 \u34892 \cf4 \cb1 \strokec4 \
\cb3         response \strokec10 =\strokec4  table.query(\cb1 \
\cb3             \cf9 \strokec9 IndexName\cf4 \strokec10 =\strokec4 user_index_name,\cb1 \
\cb3             \cf9 \strokec9 KeyConditionExpression\cf4 \strokec10 =\strokec4 Key(\cf12 \strokec12 'userId'\cf4 \strokec4 ).eq(user_id)\cb1 \
\cb3         )\cb1 \
\cb3         items \strokec10 =\strokec4  response.get(\cf12 \strokec12 'Items'\cf4 \strokec4 , [])\cb1 \
\cb3         \cb1 \
\cb3         total_answers \strokec10 =\strokec4  \cf8 \strokec8 len\cf4 \strokec4 (items)\cb1 \
\cb3         correct_answers \strokec10 =\strokec4  \cf8 \strokec8 sum\cf4 \strokec4 (\cf11 \strokec11 1\cf4 \strokec4  \cf2 \strokec2 for\cf4 \strokec4  item \cf2 \strokec2 in\cf4 \strokec4  items \cf2 \strokec2 if\cf4 \strokec4  item.get(\cf12 \strokec12 'isCorrect'\cf4 \strokec4 ))\cb1 \
\cb3         \cb1 \
\cb3         accuracy \strokec10 =\strokec4  (correct_answers \strokec10 /\strokec4  total_answers \strokec10 *\strokec4  \cf11 \strokec11 100\cf4 \strokec4 ) \cf2 \strokec2 if\cf4 \strokec4  total_answers \strokec10 >\strokec4  \cf11 \strokec11 0\cf4 \strokec4  \cf2 \strokec2 else\cf4 \strokec4  \cf11 \strokec11 0\cf4 \cb1 \strokec4 \
\cb3         \cb1 \
\cb3         stats \strokec10 =\strokec4  \{\cb1 \
\cb3             \cf12 \strokec12 'totalAnswers'\cf4 \strokec4 : total_answers,\cb1 \
\cb3             \cf12 \strokec12 'correctAnswers'\cf4 \strokec4 : correct_answers,\cb1 \
\cb3             \cf12 \strokec12 'accuracy'\cf4 \strokec4 : \cf8 \strokec8 round\cf4 \strokec4 (accuracy, \cf11 \strokec11 2\cf4 \strokec4 )\cb1 \
\cb3         \}\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(stats, \cf9 \strokec9 cls\cf4 \strokec10 =\strokec4 DecimalEncoder)\cb1 \
\cb3         \}\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf7 \strokec7 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Error: \cf6 \strokec6 \{\cf4 \strokec4 e\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 500\cf4 \strokec4 , \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(\{\cf12 \strokec12 'error'\cf4 \strokec4 : \cf7 \strokec7 str\cf4 \strokec4 (e)\})\}\cb1 \
}