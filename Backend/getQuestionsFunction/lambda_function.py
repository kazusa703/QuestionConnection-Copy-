{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red0\green0\blue0;\red144\green1\blue18;\red0\green0\blue255;\red32\green108\blue135;\red101\green76\blue29;
\red0\green0\blue109;\red19\green118\blue70;\red15\green112\blue1;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c0\c100000;\cssrgb\c14902\c49804\c60000;\cssrgb\c47451\c36863\c14902;
\cssrgb\c0\c6275\c50196;\cssrgb\c3529\c52549\c34510;\cssrgb\c0\c50196\c0;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  os\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  decimal\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  typing \cf2 \strokec2 import\cf4 \strokec4  Any, Dict, List, Optional, Set\cb1 \
\
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  boto3.dynamodb.conditions \cf2 \strokec2 import\cf4 \strokec4  Attr, Key\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 dynamodb \strokec5 =\strokec4  boto3.resource(\cf6 \strokec6 "dynamodb"\cf4 \strokec4 )\cb1 \
\
\cb3 CORS_ORIGIN \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "CORS_ORIGIN"\cf4 \strokec4 , \cf6 \strokec6 "*"\cf4 \strokec4 )\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 class\cf4 \strokec4  \cf8 \strokec8 DecimalEncoder\cf4 \strokec4 (\cf8 \strokec8 json\cf4 \strokec4 .\cf8 \strokec8 JSONEncoder\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf7 \strokec7 def\cf4 \strokec4  \cf9 \strokec9 default\cf4 \strokec4 (\cf10 \strokec10 self\cf4 \strokec4 , \cf10 \strokec10 o\cf4 \strokec4 ):\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (o, decimal.Decimal):\cb1 \
\cb3             \cf2 \strokec2 if\cf4 \strokec4  o \strokec5 %\strokec4  \cf11 \strokec11 1\cf4 \strokec4  \strokec5 ==\strokec4  \cf11 \strokec11 0\cf4 \strokec4 :\cb1 \
\cb3                 \cf2 \strokec2 return\cf4 \strokec4  \cf8 \strokec8 int\cf4 \strokec4 (o)\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \cf8 \strokec8 float\cf4 \strokec4 (o)\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \cf8 \strokec8 super\cf4 \strokec4 ().default(o)\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 def\cf4 \strokec4  \cf9 \strokec9 _resp\cf4 \strokec4 (\cf10 \strokec10 status\cf4 \strokec4 : \cf8 \strokec8 int\cf4 \strokec4 , \cf10 \strokec10 body\cf4 \strokec4 : Any) -> Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3         \cf6 \strokec6 "statusCode"\cf4 \strokec4 : status,\cb1 \
\cb3         \cf6 \strokec6 "headers"\cf4 \strokec4 : \{\cb1 \
\cb3             \cf6 \strokec6 "Content-Type"\cf4 \strokec4 : \cf6 \strokec6 "application/json"\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 "Access-Control-Allow-Origin"\cf4 \strokec4 : CORS_ORIGIN,\cb1 \
\cb3             \cf6 \strokec6 "Access-Control-Allow-Headers"\cf4 \strokec4 : \cf6 \strokec6 "*"\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 "Access-Control-Allow-Methods"\cf4 \strokec4 : \cf6 \strokec6 "OPTIONS,GET"\cf4 \strokec4 ,\cb1 \
\cb3         \},\cb1 \
\cb3         \cf6 \strokec6 "body"\cf4 \strokec4 : json.dumps(body, \cf10 \strokec10 ensure_ascii\cf4 \strokec5 =\cf7 \strokec7 False\cf4 \strokec4 , \cf10 \strokec10 cls\cf4 \strokec5 =\strokec4 DecimalEncoder),\cb1 \
\cb3     \}\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 def\cf4 \strokec4  \cf9 \strokec9 _read_query\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 : Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]) -> Dict[\cf8 \strokec8 str\cf4 \strokec4 , \cf8 \strokec8 str\cf4 \strokec4 ]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     q \strokec5 =\strokec4  event.get(\cf6 \strokec6 "queryStringParameters"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  \{\}\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\cf8 \strokec8 str\cf4 \strokec4 (k): \cf8 \strokec8 str\cf4 \strokec4 (v) \cf2 \strokec2 for\cf4 \strokec4  k, v \cf2 \strokec2 in\cf4 \strokec4  q.items()\}\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf12 \cb3 \strokec12 # --- \uc0\u9733 \u9733 \u9733  \u12371 \u12371 \u12363 \u12425 \u20462 \u27491  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\
\cf12 \cb3 \strokec12 # \uc0\u12450 \u12503 \u12522 \u12364 \u24517 \u35201 \u12392 \u12377 \u12427 \u23646 \u24615 \u12398 \u12522 \u12473 \u12488  (shareCode \u12434 \u21547 \u12416 )\cf4 \cb1 \strokec4 \
\cf12 \cb3 \strokec12 # GSI (PurposeIndex) \uc0\u12364 \u12371 \u12428 \u12425 \u12398 \u23646 \u24615 \u12434 \u12377 \u12409 \u12390 \u23556 \u24433 (Project)\u12375 \u12390 \u12356 \u12427 \u12363 \u30906 \u35469 \u12375 \u12390 \u12367 \u12384 \u12373 \u12356 \u12290 \cf4 \cb1 \strokec4 \
\cf12 \cb3 \strokec12 # \uc0\u12418 \u12375 GSI\u12364 \u12461 \u12540 \u12398 \u12415 \u12434 \u23556 \u24433 \u12375 \u12390 \u12356 \u12427 \u22580 \u21512 \u12289 GSI\u12398 \u12463 \u12456 \u12522 (use_query=True)\u12391 \u12399 \cf4 \cb1 \strokec4 \
\cf12 \cb3 \strokec12 # \uc0\u12371 \u12428 \u12425 \u12398 \u38917 \u30446 \u65288 quizItems\u12394 \u12393 \u65289 \u12399 \u21462 \u24471 \u12391 \u12365 \u12414 \u12379 \u12435 \u12290 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 PROJECTION_FIELDS \strokec5 =\strokec4  [\cb1 \
\cb3     \cf6 \strokec6 "questionId"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "title"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "purpose"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "tags"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "remarks"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "authorId"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "quizItems"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "createdAt"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "dmInviteMessage"\cf4 \strokec4 ,\cb1 \
\cb3     \cf6 \strokec6 "shareCode"\cf4 \strokec4  \cf12 \strokec12 # \uc0\u9733  shareCode \u12434 \u36861 \u21152 \cf4 \cb1 \strokec4 \
\cb3 ]\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf12 \cb3 \strokec12 # \uc0\u23646 \u24615 \u21517 \u12434  # (\u20104 \u32004 \u35486 ) \u12503 \u12524 \u12540 \u12473 \u12507 \u12523 \u12480 \u12395 \u22793 \u25563 \u12377 \u12427 \cf4 \cb1 \strokec4 \
\cf12 \cb3 \strokec12 # (\uc0\u20363 : "createdAt" -> "#createdAt")\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 PROJECTION_ATTRIBUTE_NAMES \strokec5 =\strokec4  \{\cf7 \strokec7 f\cf6 \strokec6 "#\cf7 \strokec7 \{\cf4 \strokec4 field\cf7 \strokec7 \}\cf6 \strokec6 "\cf4 \strokec4 : field \cf2 \strokec2 for\cf4 \strokec4  field \cf2 \strokec2 in\cf4 \strokec4  PROJECTION_FIELDS\}\cb1 \
\pard\pardeftab720\partightenfactor0
\cf12 \cb3 \strokec12 # \uc0\u21462 \u24471 \u12377 \u12427 \u23646 \u24615 \u12398 \u12522 \u12473 \u12488 \u12434 \u25991 \u23383 \u21015 \u12395 \u22793 \u25563  (\u20363 : "#questionId, #title, ...")\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 PROJECTION_EXPRESSION_STRING \strokec5 =\strokec4  \cf6 \strokec6 ", "\cf4 \strokec4 .join(PROJECTION_ATTRIBUTE_NAMES.keys())\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 def\cf4 \strokec4  \cf9 \strokec9 _scan_all\cf4 \strokec4 (\cf10 \strokec10 table\cf4 \strokec4 , \cf10 \strokec10 scan_kwargs\cf4 \strokec4 : Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]) -> List[Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     items: List[Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]] \strokec5 =\strokec4  []\cb1 \
\cb3     kwargs \strokec5 =\strokec4  \cf8 \strokec8 dict\cf4 \strokec4 (scan_kwargs)\cb1 \
\cb3     \cb1 \
\cb3     \cf12 \strokec12 # \uc0\u9733  \u23646 \u24615 \u12434 \u26126 \u31034 \u30340 \u12395 \u25351 \u23450 \cf4 \cb1 \strokec4 \
\cb3     kwargs[\cf6 \strokec6 "ProjectionExpression"\cf4 \strokec4 ] \strokec5 =\strokec4  PROJECTION_EXPRESSION_STRING\cb1 \
\cb3     kwargs[\cf6 \strokec6 "ExpressionAttributeNames"\cf4 \strokec4 ] \strokec5 =\strokec4  PROJECTION_ATTRIBUTE_NAMES\cb1 \
\cb3     \cb1 \
\cb3     \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 f\cf6 \strokec6 "[DEBUG] Scan kwargs: \cf7 \strokec7 \{\cf4 \strokec4 kwargs\cf7 \strokec7 \}\cf6 \strokec6 "\cf4 \strokec4 ) \cf12 \strokec12 # \uc0\u12487 \u12496 \u12483 \u12464 \u12525 \u12464 \cf4 \cb1 \strokec4 \
\
\cb3     \cf2 \strokec2 while\cf4 \strokec4  \cf7 \strokec7 True\cf4 \strokec4 :\cb1 \
\cb3         resp \strokec5 =\strokec4  table.scan(\strokec5 **\strokec4 kwargs)\cb1 \
\cb3         items.extend(resp.get(\cf6 \strokec6 "Items"\cf4 \strokec4 , []))\cb1 \
\cb3         lek \strokec5 =\strokec4  resp.get(\cf6 \strokec6 "LastEvaluatedKey"\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  lek:\cb1 \
\cb3             \cf2 \strokec2 break\cf4 \cb1 \strokec4 \
\cb3         kwargs[\cf6 \strokec6 "ExclusiveStartKey"\cf4 \strokec4 ] \strokec5 =\strokec4  lek\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  items\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 def\cf4 \strokec4  \cf9 \strokec9 _query_all\cf4 \strokec4 (\cf10 \strokec10 table\cf4 \strokec4 , \cf10 \strokec10 query_kwargs\cf4 \strokec4 : Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]) -> List[Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]]:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     items: List[Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any]] \strokec5 =\strokec4  []\cb1 \
\cb3     kwargs \strokec5 =\strokec4  \cf8 \strokec8 dict\cf4 \strokec4 (query_kwargs)\cb1 \
\
\cb3     \cf12 \strokec12 # \uc0\u9733  \u23646 \u24615 \u12434 \u26126 \u31034 \u30340 \u12395 \u25351 \u23450 \cf4 \cb1 \strokec4 \
\cb3     kwargs[\cf6 \strokec6 "ProjectionExpression"\cf4 \strokec4 ] \strokec5 =\strokec4  PROJECTION_EXPRESSION_STRING\cb1 \
\cb3     kwargs[\cf6 \strokec6 "ExpressionAttributeNames"\cf4 \strokec4 ] \strokec5 =\strokec4  PROJECTION_ATTRIBUTE_NAMES\cb1 \
\cb3     \cb1 \
\cb3     \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 f\cf6 \strokec6 "[DEBUG] Query kwargs: \cf7 \strokec7 \{\cf4 \strokec4 kwargs\cf7 \strokec7 \}\cf6 \strokec6 "\cf4 \strokec4 ) \cf12 \strokec12 # \uc0\u12487 \u12496 \u12483 \u12464 \u12525 \u12464 \cf4 \cb1 \strokec4 \
\
\cb3     \cf2 \strokec2 while\cf4 \strokec4  \cf7 \strokec7 True\cf4 \strokec4 :\cb1 \
\cb3         resp \strokec5 =\strokec4  table.query(\strokec5 **\strokec4 kwargs)\cb1 \
\cb3         items.extend(resp.get(\cf6 \strokec6 "Items"\cf4 \strokec4 , []))\cb1 \
\cb3         lek \strokec5 =\strokec4  resp.get(\cf6 \strokec6 "LastEvaluatedKey"\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  lek:\cb1 \
\cb3             \cf2 \strokec2 break\cf4 \cb1 \strokec4 \
\cb3         kwargs[\cf6 \strokec6 "ExclusiveStartKey"\cf4 \strokec4 ] \strokec5 =\strokec4  lek\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  items\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf12 \cb3 \strokec12 # --- \uc0\u9733 \u9733 \u9733  \u12371 \u12371 \u12414 \u12391 \u20462 \u27491  \u9733 \u9733 \u9733  ---\cf4 \cb1 \strokec4 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 def\cf4 \strokec4  \cf9 \strokec9 handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 if\cf4 \strokec4  event.get(\cf6 \strokec6 "httpMethod"\cf4 \strokec4 ) \strokec5 ==\strokec4  \cf6 \strokec6 "OPTIONS"\cf4 \strokec4 :\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf11 \strokec11 200\cf4 \strokec4 , \{\cf6 \strokec6 "ok"\cf4 \strokec4 : \cf7 \strokec7 True\cf4 \strokec4 \})\cb1 \
\
\cb3     questions_table_name \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "QUESTIONS_TABLE"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  os.environ.get(\cf6 \strokec6 "QUESTIONS_TABLE_NAME"\cf4 \strokec4 )\cb1 \
\cb3     bookmarks_table_name \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "BOOKMARKS_TABLE"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  os.environ.get(\cf6 \strokec6 "BOOKMARKS_TABLE_NAME"\cf4 \strokec4 )\cb1 \
\cb3     purpose_index_name \strokec5 =\strokec4  os.environ.get(\cf6 \strokec6 "PURPOSE_INDEX_NAME"\cf4 \strokec4 , \cf6 \strokec6 "PurposeIndex"\cf4 \strokec4 )\cb1 \
\
\cb3     \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  questions_table_name:\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf11 \strokec11 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "Server misconfiguration: QUESTIONS_TABLE is not set."\cf4 \strokec4 \})\cb1 \
\
\cb3     questions_table \strokec5 =\strokec4  dynamodb.Table(questions_table_name)\cb1 \
\cb3     bookmarks_table \strokec5 =\strokec4  dynamodb.Table(bookmarks_table_name) \cf2 \strokec2 if\cf4 \strokec4  bookmarks_table_name \cf2 \strokec2 else\cf4 \strokec4  \cf7 \strokec7 None\cf4 \cb1 \strokec4 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         params \strokec5 =\strokec4  _read_query(event)\cb1 \
\cb3         code \strokec5 =\strokec4  (params.get(\cf6 \strokec6 "code"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  \cf6 \strokec6 ""\cf4 \strokec4 ).strip().lower()\cb1 \
\cb3         purpose \strokec5 =\strokec4  (params.get(\cf6 \strokec6 "purpose"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  \cf6 \strokec6 ""\cf4 \strokec4 ).strip()\cb1 \
\cb3         category \strokec5 =\strokec4  (params.get(\cf6 \strokec6 "category"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  params.get(\cf6 \strokec6 "tag"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  \cf6 \strokec6 ""\cf4 \strokec4 ).strip()\cb1 \
\cb3         bookmarked_by \strokec5 =\strokec4  (params.get(\cf6 \strokec6 "bookmarkedBy"\cf4 \strokec4 ) \cf7 \strokec7 or\cf4 \strokec4  \cf6 \strokec6 ""\cf4 \strokec4 ).strip()\cb1 \
\
\cb3         \cf12 \strokec12 # 1) shareCode \uc0\u26908 \u32034 \u12434 \u26368 \u20778 \u20808 \u65288 \u23436 \u20840 \u19968 \u33268 \u65289 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  code:\cb1 \
\cb3             \cf9 \strokec9 print\cf4 \strokec4 (\cf7 \strokec7 f\cf6 \strokec6 "[get_questions] code search: \cf7 \strokec7 \{\cf4 \strokec4 code\cf7 \strokec7 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3             fe \strokec5 =\strokec4  Attr(\cf6 \strokec6 "shareCode"\cf4 \strokec4 ).eq(code)\cb1 \
\cb3             \cb1 \
\cb3             \cf12 \strokec12 # \uc0\u9733  shareCode\u26908 \u32034 \u26178 \u12418  ProjectionExpression \u12434 \u28193 \u12377 \cf4 \cb1 \strokec4 \
\cb3             scan_kwargs \strokec5 =\strokec4  \{\cb1 \
\cb3                 \cf6 \strokec6 "FilterExpression"\cf4 \strokec4 : fe\cb1 \
\cb3             \}\cb1 \
\cb3             items \strokec5 =\strokec4  _scan_all(questions_table, scan_kwargs)\cb1 \
\cb3             \cb1 \
\cb3             items_sorted \strokec5 =\strokec4  \cf9 \strokec9 sorted\cf4 \strokec4 (\cb1 \
\cb3                 (it \cf2 \strokec2 for\cf4 \strokec4  it \cf2 \strokec2 in\cf4 \strokec4  items \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (it.get(\cf6 \strokec6 "createdAt"\cf4 \strokec4 ), \cf8 \strokec8 str\cf4 \strokec4 ) \cf7 \strokec7 and\cf4 \strokec4  it[\cf6 \strokec6 "createdAt"\cf4 \strokec4 ]),\cb1 \
\cb3                 \cf10 \strokec10 key\cf4 \strokec5 =\cf7 \strokec7 lambda\cf4 \strokec4  \cf10 \strokec10 x\cf4 \strokec4 : x[\cf6 \strokec6 "createdAt"\cf4 \strokec4 ],\cb1 \
\cb3                 \cf10 \strokec10 reverse\cf4 \strokec5 =\cf7 \strokec7 True\cf4 \strokec4 ,\cb1 \
\cb3             )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf11 \strokec11 200\cf4 \strokec4 , items_sorted)\cb1 \
\
\cb3         \cf12 \strokec12 # 2) \uc0\u12502 \u12483 \u12463 \u12510 \u12540 \u12463 \u65288 \u24517 \u35201 \u26178 \u12398 \u12415 \u65289 \cf4 \cb1 \strokec4 \
\cb3         bookmarked_ids: Optional[Set[\cf8 \strokec8 str\cf4 \strokec4 ]] \strokec5 =\strokec4  \cf7 \strokec7 None\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  bookmarked_by:\cb1 \
\cb3             \cf12 \strokec12 # (\uc0\u12502 \u12483 \u12463 \u12510 \u12540 \u12463 \u20966 \u29702 \u12399 \u22793 \u26356 \u12394 \u12375 )\cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  bookmarks_table:\cb1 \
\cb3                 \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf11 \strokec11 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf6 \strokec6 "BOOKMARKS_TABLE is not set but bookmarkedBy was provided."\cf4 \strokec4 \})\cb1 \
\cb3             collected: Set[\cf8 \strokec8 str\cf4 \strokec4 ] \strokec5 =\strokec4  \cf8 \strokec8 set\cf4 \strokec4 ()\cb1 \
\cb3             query_kwargs \strokec5 =\strokec4  \{\cb1 \
\cb3                 \cf6 \strokec6 "KeyConditionExpression"\cf4 \strokec4 : Key(\cf6 \strokec6 "userId"\cf4 \strokec4 ).eq(bookmarked_by),\cb1 \
\cb3                 \cf6 \strokec6 "ProjectionExpression"\cf4 \strokec4 : \cf6 \strokec6 "questionId"\cf4 \strokec4 , \cf12 \strokec12 # \uc0\u12371 \u12371 \u12399  questionId \u12384 \u12369 \u12391 OK\cf4 \cb1 \strokec4 \
\cb3             \}\cb1 \
\cb3             \cf2 \strokec2 while\cf4 \strokec4  \cf7 \strokec7 True\cf4 \strokec4 :\cb1 \
\cb3                 resp \strokec5 =\strokec4  bookmarks_table.query(\strokec5 **\strokec4 query_kwargs)\cb1 \
\cb3                 \cf2 \strokec2 for\cf4 \strokec4  it \cf2 \strokec2 in\cf4 \strokec4  resp.get(\cf6 \strokec6 "Items"\cf4 \strokec4 , []):\cb1 \
\cb3                     qid \strokec5 =\strokec4  it.get(\cf6 \strokec6 "questionId"\cf4 \strokec4 )\cb1 \
\cb3                     \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (qid, \cf8 \strokec8 str\cf4 \strokec4 ):\cb1 \
\cb3                         collected.add(qid)\cb1 \
\cb3                 lek \strokec5 =\strokec4  resp.get(\cf6 \strokec6 "LastEvaluatedKey"\cf4 \strokec4 )\cb1 \
\cb3                 \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  lek:\cb1 \
\cb3                     \cf2 \strokec2 break\cf4 \cb1 \strokec4 \
\cb3                 query_kwargs[\cf6 \strokec6 "ExclusiveStartKey"\cf4 \strokec4 ] \strokec5 =\strokec4  lek\cb1 \
\cb3             bookmarked_ids \strokec5 =\strokec4  collected\cb1 \
\cb3             \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  bookmarked_ids:\cb1 \
\cb3                 \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf11 \strokec11 200\cf4 \strokec4 , [])\cb1 \
\
\cb3         \cf12 \strokec12 # 3) \uc0\u30446 \u30340 \u12354 \u12426 \u12394 \u12425  GSI\u12289 \u12394 \u12369 \u12428 \u12400 Scan\cf4 \cb1 \strokec4 \
\cb3         use_query \strokec5 =\strokec4  \cf8 \strokec8 bool\cf4 \strokec4 (purpose)\cb1 \
\cb3         dynamo_kwargs: Dict[\cf8 \strokec8 str\cf4 \strokec4 , Any] \strokec5 =\strokec4  \{\}\cb1 \
\cb3         filter_expr \strokec5 =\strokec4  \cf7 \strokec7 None\cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 if\cf4 \strokec4  use_query:\cb1 \
\cb3             dynamo_kwargs[\cf6 \strokec6 "IndexName"\cf4 \strokec4 ] \strokec5 =\strokec4  purpose_index_name\cb1 \
\cb3             dynamo_kwargs[\cf6 \strokec6 "KeyConditionExpression"\cf4 \strokec4 ] \strokec5 =\strokec4  Key(\cf6 \strokec6 "purpose"\cf4 \strokec4 ).eq(purpose)\cb1 \
\
\cb3         \cf12 \strokec12 # (\uc0\u12479 \u12464 \u12501 \u12451 \u12523 \u12479 \u12289 \u12502 \u12483 \u12463 \u12510 \u12540 \u12463 \u26465 \u20214 \u12399 \u22793 \u26356 \u12394 \u12375 )\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  category:\cb1 \
\cb3             fe \strokec5 =\strokec4  Attr(\cf6 \strokec6 "tags"\cf4 \strokec4 ).contains(category)\cb1 \
\cb3             filter_expr \strokec5 =\strokec4  fe \cf2 \strokec2 if\cf4 \strokec4  filter_expr \cf7 \strokec7 is\cf4 \strokec4  \cf7 \strokec7 None\cf4 \strokec4  \cf2 \strokec2 else\cf4 \strokec4  (filter_expr \strokec5 &\strokec4  fe)\cb1 \
\
\cb3         python_filter_bookmarks \strokec5 =\strokec4  \cf7 \strokec7 False\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  bookmarked_ids \cf7 \strokec7 is\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  \cf7 \strokec7 None\cf4 \strokec4 :\cb1 \
\cb3             \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 len\cf4 \strokec4 (bookmarked_ids) \strokec5 <=\strokec4  \cf11 \strokec11 100\cf4 \strokec4 :\cb1 \
\cb3                 fe \strokec5 =\strokec4  Attr(\cf6 \strokec6 "questionId"\cf4 \strokec4 ).is_in(\cf8 \strokec8 list\cf4 \strokec4 (bookmarked_ids))\cb1 \
\cb3                 filter_expr \strokec5 =\strokec4  fe \cf2 \strokec2 if\cf4 \strokec4  filter_expr \cf7 \strokec7 is\cf4 \strokec4  \cf7 \strokec7 None\cf4 \strokec4  \cf2 \strokec2 else\cf4 \strokec4  (filter_expr \strokec5 &\strokec4  fe)\cb1 \
\cb3             \cf2 \strokec2 else\cf4 \strokec4 :\cb1 \
\cb3                 python_filter_bookmarks \strokec5 =\strokec4  \cf7 \strokec7 True\cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 if\cf4 \strokec4  filter_expr \cf7 \strokec7 is\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  \cf7 \strokec7 None\cf4 \strokec4 :\cb1 \
\cb3             dynamo_kwargs[\cf6 \strokec6 "FilterExpression"\cf4 \strokec4 ] \strokec5 =\strokec4  filter_expr\cb1 \
\
\cb3         \cf2 \strokec2 if\cf4 \strokec4  use_query:\cb1 \
\cb3             items \strokec5 =\strokec4  _query_all(questions_table, dynamo_kwargs)\cb1 \
\cb3         \cf2 \strokec2 else\cf4 \strokec4 :\cb1 \
\cb3             items \strokec5 =\strokec4  _scan_all(questions_table, dynamo_kwargs)\cb1 \
\
\cb3         \cf2 \strokec2 if\cf4 \strokec4  python_filter_bookmarks \cf7 \strokec7 and\cf4 \strokec4  bookmarked_ids \cf7 \strokec7 is\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  \cf7 \strokec7 None\cf4 \strokec4 :\cb1 \
\cb3             items \strokec5 =\strokec4  [it \cf2 \strokec2 for\cf4 \strokec4  it \cf2 \strokec2 in\cf4 \strokec4  items \cf2 \strokec2 if\cf4 \strokec4  it.get(\cf6 \strokec6 "questionId"\cf4 \strokec4 ) \cf7 \strokec7 in\cf4 \strokec4  bookmarked_ids]\cb1 \
\
\cb3         items_sorted \strokec5 =\strokec4  \cf9 \strokec9 sorted\cf4 \strokec4 (\cb1 \
\cb3             (it \cf2 \strokec2 for\cf4 \strokec4  it \cf2 \strokec2 in\cf4 \strokec4  items \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 isinstance\cf4 \strokec4 (it.get(\cf6 \strokec6 "createdAt"\cf4 \strokec4 ), \cf8 \strokec8 str\cf4 \strokec4 ) \cf7 \strokec7 and\cf4 \strokec4  it[\cf6 \strokec6 "createdAt"\cf4 \strokec4 ]),\cb1 \
\cb3             \cf10 \strokec10 key\cf4 \strokec5 =\cf7 \strokec7 lambda\cf4 \strokec4  \cf10 \strokec10 x\cf4 \strokec4 : x[\cf6 \strokec6 "createdAt"\cf4 \strokec4 ],\cb1 \
\cb3             \cf10 \strokec10 reverse\cf4 \strokec5 =\cf7 \strokec7 True\cf4 \strokec4 ,\cb1 \
\cb3         )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf11 \strokec11 200\cf4 \strokec4 , items_sorted)\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf8 \strokec8 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  _resp(\cf11 \strokec11 500\cf4 \strokec4 , \{\cf6 \strokec6 "message"\cf4 \strokec4 : \cf7 \strokec7 f\cf6 \strokec6 "Internal error: \cf7 \strokec7 \{\cf8 \strokec8 str\cf4 \strokec4 (e)\cf7 \strokec7 \}\cf6 \strokec6 "\cf4 \strokec4 \})\cb1 \
\
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 def\cf4 \strokec4  \cf9 \strokec9 lambda_handler\cf4 \strokec4 (\cf10 \strokec10 event\cf4 \strokec4 , \cf10 \strokec10 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 return\cf4 \strokec4  handler(event, context)\cb1 \
}