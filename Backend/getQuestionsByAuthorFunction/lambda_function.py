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
\cf2 \cb3 \strokec2 from\cf4 \strokec4  boto3.dynamodb.conditions \cf2 \strokec2 import\cf4 \strokec4  Key, Attr\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  os\cb1 \
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
\
\pard\pardeftab720\partightenfactor0
\cf12 \cb3 \strokec12 # --- \uc0\u21462 \u24471 \u12377 \u12427 \u23646 \u24615  (ProjectionExpression) ---\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 PROJECTION_FIELDS \strokec9 =\strokec4  [\cb1 \
\cb3     \cf11 \strokec11 "questionId"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "title"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "purpose"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "tags"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "remarks"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "authorId"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "quizItems"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "createdAt"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "dmInviteMessage"\cf4 \strokec4 ,\cb1 \
\cb3     \cf11 \strokec11 "shareCode"\cf4 \cb1 \strokec4 \
\cb3 ]\cb1 \
\cb3 PROJECTION_ATTRIBUTE_NAMES \strokec9 =\strokec4  \{\cf5 \strokec5 f\cf11 \strokec11 "#\cf5 \strokec5 \{\cf4 \strokec4 field\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 : field \cf2 \strokec2 for\cf4 \strokec4  field \cf2 \strokec2 in\cf4 \strokec4  PROJECTION_FIELDS\}\cb1 \
\cb3 PROJECTION_EXPRESSION_STRING \strokec9 =\strokec4  \cf11 \strokec11 ", "\cf4 \strokec4 .join(PROJECTION_ATTRIBUTE_NAMES.keys())\cb1 \
\pard\pardeftab720\partightenfactor0
\cf12 \cb3 \strokec12 # --- \uc0\u12371 \u12371 \u12414 \u12391  ---\cf4 \cb1 \strokec4 \
\
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 def\cf4 \strokec4  \cf7 \strokec7 lambda_handler\cf4 \strokec4 (\cf8 \strokec8 event\cf4 \strokec4 , \cf8 \strokec8 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cb1 \
\cb3     table_name \strokec9 =\strokec4  os.environ.get(\cf11 \strokec11 "QUESTIONS_TABLE"\cf4 \strokec4 ) \cf5 \strokec5 or\cf4 \strokec4  os.environ.get(\cf11 \strokec11 "QUESTIONS_TABLE_NAME"\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  \cf5 \strokec5 not\cf4 \strokec4  table_name:\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 500\cf4 \strokec4 , \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 'error'\cf4 \strokec4 : \cf11 \strokec11 'QUESTIONS_TABLE environment variable is not set'\cf4 \strokec4 \})\}\cb1 \
\cb3         \cb1 \
\cb3     table \strokec9 =\strokec4  dynamodb.Table(table_name)\cb1 \
\cb3     author_index_name \strokec9 =\strokec4  \cf11 \strokec11 'AuthorIdIndex'\cf4 \strokec4  \cf12 \strokec12 # GSI\uc0\u21517 \cf4 \cb1 \strokec4 \
\cb3     \cb1 \
\cb3     \cf12 \strokec12 # CORS preflight (OPTIONS\uc0\u12513 \u12477 \u12483 \u12489 \u12408 \u12398 \u23550 \u24540 )\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 if\cf4 \strokec4  event.get(\cf11 \strokec11 "httpMethod"\cf4 \strokec4 ) \strokec9 ==\strokec4  \cf11 \strokec11 "OPTIONS"\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf11 \strokec11 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3                 \cf11 \strokec11 "Access-Control-Allow-Origin"\cf4 \strokec4 : \cf11 \strokec11 "*"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 "Access-Control-Allow-Headers"\cf4 \strokec4 : \cf11 \strokec11 "*"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 "Access-Control-Allow-Methods"\cf4 \strokec4 : \cf11 \strokec11 "OPTIONS,GET"\cf4 \cb1 \strokec4 \
\cb3             \},\cb1 \
\cb3             \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 "ok"\cf4 \strokec4 : \cf5 \strokec5 True\cf4 \strokec4 \})\cb1 \
\cb3         \}\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         author_id \strokec9 =\strokec4  event[\cf11 \strokec11 'pathParameters'\cf4 \strokec4 ][\cf11 \strokec11 'userId'\cf4 \strokec4 ]\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf5 \strokec5 not\cf4 \strokec4  author_id:\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 400\cf4 \strokec4 , \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 'error'\cf4 \strokec4 : \cf11 \strokec11 'userId (authorId) is required'\cf4 \strokec4 \})\}\cb1 \
\
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "[get_questions_by_author] AuthorId: \cf5 \strokec5 \{\cf4 \strokec4 author_id\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\
\cb3         query_kwargs \strokec9 =\strokec4  \{\cb1 \
\cb3             \cf11 \strokec11 "IndexName"\cf4 \strokec4 : author_index_name,\cb1 \
\cb3             \cf11 \strokec11 "KeyConditionExpression"\cf4 \strokec4 : Key(\cf11 \strokec11 'authorId'\cf4 \strokec4 ).eq(author_id),\cb1 \
\cb3             \cf11 \strokec11 "ProjectionExpression"\cf4 \strokec4 : PROJECTION_EXPRESSION_STRING,\cb1 \
\cb3             \cf11 \strokec11 "ExpressionAttributeNames"\cf4 \strokec4 : PROJECTION_ATTRIBUTE_NAMES\cb1 \
\cb3         \}\cb1 \
\cb3         \cb1 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "[DEBUG] Query kwargs: \cf5 \strokec5 \{\cf4 \strokec4 json.dumps(query_kwargs, \cf8 \strokec8 default\cf4 \strokec9 =\cf6 \strokec6 str\cf4 \strokec4 )\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         response \strokec9 =\strokec4  table.query(\strokec9 **\strokec4 query_kwargs)\cb1 \
\cb3         items \strokec9 =\strokec4  response.get(\cf11 \strokec11 'Items'\cf4 \strokec4 , [])\cb1 \
\
\cb3         sorted_items \strokec9 =\strokec4  \cf7 \strokec7 sorted\cf4 \strokec4 (items, \cf8 \strokec8 key\cf4 \strokec9 =\cf5 \strokec5 lambda\cf4 \strokec4  \cf8 \strokec8 x\cf4 \strokec4 : x.get(\cf11 \strokec11 'createdAt'\cf4 \strokec4 , \cf11 \strokec11 ''\cf4 \strokec4 ), \cf8 \strokec8 reverse\cf4 \strokec9 =\cf5 \strokec5 True\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "[get_questions_by_author] Found \cf5 \strokec5 \{\cf7 \strokec7 len\cf4 \strokec4 (sorted_items)\cf5 \strokec5 \}\cf11 \strokec11  items."\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf12 \strokec12 # \uc0\u9733 \u9733 \u9733  \u12371 \u12371 \u12395 \u12487 \u12496 \u12483 \u12464 \u12525 \u12464 \u12434 \u36861 \u21152  \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\cb3         \cf12 \strokec12 # \uc0\u12450 \u12503 \u12522 \u12395 \u36820 \u12377 \u30452 \u21069 \u12398 \u12487 \u12540 \u12479 \u65288 sorted_items\u65289 \u12434 \u12525 \u12464 \u12395 \u20986 \u21147 \cf4 \cb1 \strokec4 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "[DEBUG] Response body: \cf5 \strokec5 \{\cf4 \strokec4 json.dumps(sorted_items, \cf8 \strokec8 cls\cf4 \strokec9 =\strokec4 DecimalEncoder)\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\cb3         \cf12 \strokec12 # \uc0\u9733 \u9733 \u9733  \u12371 \u12371 \u12414 \u12391  \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 200\cf4 \strokec4 ,\cb1 \
\cb3             \cf11 \strokec11 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3                 \cf11 \strokec11 "Content-Type"\cf4 \strokec4 : \cf11 \strokec11 "application/json"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 "Access-Control-Allow-Origin"\cf4 \strokec4 : \cf11 \strokec11 "*"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 "Access-Control-Allow-Headers"\cf4 \strokec4 : \cf11 \strokec11 "*"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 "Access-Control-Allow-Methods"\cf4 \strokec4 : \cf11 \strokec11 "OPTIONS,GET"\cf4 \cb1 \strokec4 \
\cb3             \},\cb1 \
\cb3             \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(sorted_items, \cf8 \strokec8 cls\cf4 \strokec9 =\strokec4 DecimalEncoder)\cb1 \
\cb3         \}\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf6 \strokec6 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf7 \strokec7 print\cf4 \strokec4 (\cf5 \strokec5 f\cf11 \strokec11 "Error: \cf5 \strokec5 \{\cf4 \strokec4 e\cf5 \strokec5 \}\cf11 \strokec11 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf11 \strokec11 'statusCode'\cf4 \strokec4 : \cf10 \strokec10 500\cf4 \strokec4 , \cb1 \
\cb3             \cf11 \strokec11 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3                 \cf11 \strokec11 "Content-Type"\cf4 \strokec4 : \cf11 \strokec11 "application/json"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 "Access-Control-Allow-Origin"\cf4 \strokec4 : \cf11 \strokec11 "*"\cf4 \cb1 \strokec4 \
\cb3             \},\cb1 \
\cb3             \cf11 \strokec11 'body'\cf4 \strokec4 : json.dumps(\{\cf11 \strokec11 'error'\cf4 \strokec4 : \cf6 \strokec6 str\cf4 \strokec4 (e)\})\cb1 \
\cb3         \}\cb1 \
}