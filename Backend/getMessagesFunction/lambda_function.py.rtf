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
\cf2 \cb3 \strokec2 from\cf4 \strokec4  boto3.dynamodb.conditions \cf2 \strokec2 import\cf4 \strokec4  Key\cb1 \
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
\cb3 table \strokec9 =\strokec4  dynamodb.Table(\cf11 \strokec11 'Messages'\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 def\cf4 \strokec4  \cf7 \strokec7 lambda_handler\cf4 \strokec4 (\cf8 \strokec8 event\cf4 \strokec4 , \cf8 \strokec8 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf12 \strokec12 # \uc0\u12497 \u12473 \u12497 \u12521 \u12513 \u12540 \u12479 \u12363 \u12425 \u12473 \u12524 \u12483 \u12489 ID\u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         thread_id \strokec9 =\strokec4  event[\cf11 \strokec11 'pathParameters'\cf4 \strokec4 ][\cf11 \strokec11 'threadId'\cf4 \strokec4 ]\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf5 \strokec5 not\cf4 \strokec4  thread_id:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 400\cf4 \strokec4 , \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 'error'\cf4 \strokec4 : \cf11 \strokec11 'threadId is required'\cf4 \strokec4 \})\}\cb1 \
\
\cb3         \cf12 \strokec12 # 'threadId'\uc0\u12364 \u19968 \u33268 \u12377 \u12427 \u12450 \u12452 \u12486 \u12512 \u12434 \u12463 \u12456 \u12522 \u12391 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         response \strokec9 =\strokec4  table.query(\cb1 \
\cb3             \cf8 \strokec8 KeyConditionExpression\cf4 \strokec9 =\strokec4 Key(\cf11 \strokec11 'threadId'\cf4 \strokec4 ).eq(thread_id)\cb1 \
\cb3         )\cb1 \
\cb3         items \strokec9 =\strokec4  response.get(\cf11 \strokec11 'Items'\cf4 \strokec4 , [])\cb1 \
\cb3         \cb1 \
\cb3         \cf12 \strokec12 # \uc0\u12479 \u12452 \u12512 \u12473 \u12479 \u12531 \u12503 \u12391 \u26119 \u38918 \u65288 \u21476 \u12356 \u12418 \u12398 \u12364 \u20808 \u38957 \u65289 \u12395 \u12477 \u12540 \u12488 \cf4 \cb1 \strokec4 \
\cb3         sorted_items \strokec9 =\strokec4  \cf7 \strokec7 sorted\cf4 \strokec4 (items, \cf8 \strokec8 key\cf4 \strokec9 =\cf5 \strokec5 lambda\cf4 \strokec4  \cf8 \strokec8 x\cf4 \strokec4 : x.get(\cf11 \strokec11 'timestamp'\cf4 \strokec4 , \cf11 \strokec11 ''\cf4 \strokec4 ))\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(sorted_items, \cf8 \strokec8 cls\cf4 \strokec9 =\strokec4 DecimalEncoder)\cb1 \
\cb3         \}\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf6 \strokec6 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "Error: \cf5 \strokec5 \{\cf4 \strokec4 e\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 500\cf4 \strokec4 , \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 'error'\cf4 \strokec4 : \cf6 \strokec6 str\cf4 \strokec4 (e)\})\}\cb1 \
}