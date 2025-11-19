{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red0\green0\blue0;\red144\green1\blue18;\red15\green112\blue1;\red0\green0\blue255;\red101\green76\blue29;
\red0\green0\blue109;\red19\green118\blue70;\red32\green108\blue135;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c50196\c0;\cssrgb\c0\c0\c100000;\cssrgb\c47451\c36863\c14902;
\cssrgb\c0\c6275\c50196;\cssrgb\c3529\c52549\c34510;\cssrgb\c14902\c49804\c60000;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  boto3.dynamodb.conditions \cf2 \strokec2 import\cf4 \strokec4  Key, Attr\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 dynamodb \strokec5 =\strokec4  boto3.resource(\cf6 \strokec6 'dynamodb'\cf4 \strokec4 )\cb1 \
\cb3 table \strokec5 =\strokec4  dynamodb.Table(\cf6 \strokec6 'AnswersLog'\cf4 \strokec4 )\cb1 \
\cb3 user_index_name \strokec5 =\strokec4  \cf6 \strokec6 'UserIndex'\cf4 \strokec4  \cf7 \strokec7 # GSI\uc0\u21517 \cf4 \cb1 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf7 \strokec7 # Cognito\uc0\u35469 \u35388 \u24773 \u22577 \u12363 \u12425 \u12518 \u12540 \u12470 \u12540 ID\u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         user_id \strokec5 =\strokec4  event[\cf6 \strokec6 'requestContext'\cf4 \strokec4 ][\cf6 \strokec6 'authorizer'\cf4 \strokec4 ][\cf6 \strokec6 'claims'\cf4 \strokec4 ][\cf6 \strokec6 'sub'\cf4 \strokec4 ]\cb1 \
\cb3         \cb1 \
\cb3         \cf7 \strokec7 # \uc0\u12463 \u12456 \u12522 \u12497 \u12521 \u12513 \u12540 \u12479 \u12363 \u12425 \u36074 \u21839 ID\u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         question_id \strokec5 =\strokec4  event[\cf6 \strokec6 'queryStringParameters'\cf4 \strokec4 ][\cf6 \strokec6 'questionId'\cf4 \strokec4 ]\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  user_id \cf8 \strokec8 or\cf4 \strokec4  \cf8 \strokec8 not\cf4 \strokec4  question_id:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cf6 \strokec6 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 400\cf4 \strokec4 , \cf6 \strokec6 'body'\cf4 \strokec4 : json.dumps(\{\cf6 \strokec6 'error'\cf4 \strokec4 : \cf6 \strokec6 'userId and questionId are required'\cf4 \strokec4 \})\}\cb1 \
\
\cb3         \cf7 \strokec7 # UserIndex GSI\uc0\u12434 \u20351 \u12387 \u12390 \u12289 \u29305 \u23450 \u12398 \u12518 \u12540 \u12470 \u12540 \u12398 \u22238 \u31572 \u35352 \u37682 \u12434 \u12463 \u12456 \u12522 \cf4 \cb1 \strokec4 \
\cb3         response \strokec5 =\strokec4  table.query(\cb1 \
\cb3             \cf10 \strokec10 IndexName\cf4 \strokec5 =\strokec4 user_index_name,\cb1 \
\cb3             \cf10 \strokec10 KeyConditionExpression\cf4 \strokec5 =\strokec4 Key(\cf6 \strokec6 'userId'\cf4 \strokec4 ).eq(user_id)\cb1 \
\cb3         )\cb1 \
\cb3         items \strokec5 =\strokec4  response.get(\cf6 \strokec6 'Items'\cf4 \strokec4 , [])\cb1 \
\cb3         \cb1 \
\cb3         \cf7 \strokec7 # \uc0\u12463 \u12456 \u12522 \u32080 \u26524 \u12398 \u20013 \u12363 \u12425 \u12289 \u25351 \u23450 \u12373 \u12428 \u12383 questionId\u12398 \u35352 \u37682 \u12364 \u23384 \u22312 \u12377 \u12427 \u12363 \u12434 \u12481 \u12455 \u12483 \u12463 \cf4 \cb1 \strokec4 \
\cb3         has_answered \strokec5 =\strokec4  \cf9 \strokec9 any\cf4 \strokec4 (item.get(\cf6 \strokec6 'questionId'\cf4 \strokec4 ) \strokec5 ==\strokec4  question_id \cf2 \strokec2 for\cf4 \strokec4  item \cf2 \strokec2 in\cf4 \strokec4  items)\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf6 \strokec6 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 'body'\cf4 \strokec4 : json.dumps(\{\cf6 \strokec6 'hasAnswered'\cf4 \strokec4 : has_answered\})\cb1 \
\cb3         \}\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf12 \strokec12 KeyError\cf4 \strokec4 :\cb1 \
\cb3          \cf7 \strokec7 # userId\uc0\u12420 questionId\u12364 \u35211 \u12388 \u12363 \u12425 \u12394 \u12356 \u22580 \u21512 \u12398 \u12456 \u12521 \u12540 \u12495 \u12531 \u12489 \u12522 \u12531 \u12464 \cf4 \cb1 \strokec4 \
\cb3          \cf2 \strokec2 return\cf4 \strokec4  \{\cf6 \strokec6 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 400\cf4 \strokec4 , \cf6 \strokec6 'body'\cf4 \strokec4 : json.dumps(\{\cf6 \strokec6 'error'\cf4 \strokec4 : \cf6 \strokec6 'Missing required parameters in event data'\cf4 \strokec4 \})\}\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf12 \strokec12 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf9 \strokec9 print\cf4 \strokec4 (\cf8 \strokec8 f\cf6 \strokec6 "Error: \cf8 \strokec8 \{\cf4 \strokec4 e\cf8 \strokec8 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cf6 \strokec6 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 500\cf4 \strokec4 , \cf6 \strokec6 'body'\cf4 \strokec4 : json.dumps(\{\cf6 \strokec6 'error'\cf4 \strokec4 : \cf12 \strokec12 str\cf4 \strokec4 (e)\})\}\cb1 \
}