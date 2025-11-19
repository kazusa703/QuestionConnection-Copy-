{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red15\green112\blue1;\red0\green0\blue0;\red144\green1\blue18;\red32\green108\blue135;\red0\green0\blue255;
\red101\green76\blue29;\red0\green0\blue109;\red19\green118\blue70;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c50196\c0;\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c14902\c49804\c60000;\cssrgb\c0\c0\c100000;
\cssrgb\c47451\c36863\c14902;\cssrgb\c0\c6275\c50196;\cssrgb\c3529\c52549\c34510;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  os\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  logging\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  botocore.exceptions \cf2 \strokec2 import\cf4 \strokec4  ClientError\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # \uc0\u12525 \u12460 \u12540 \u12398 \u35373 \u23450 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 logger \strokec6 =\strokec4  logging.getLogger()\cb1 \
\cb3 logger.setLevel(logging.INFO)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # AWS\uc0\u12463 \u12521 \u12452 \u12450 \u12531 \u12488 \u12398 \u21021 \u26399 \u21270 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 dynamodb \strokec6 =\strokec4  boto3.resource(\cf7 \strokec7 'dynamodb'\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # --- \uc0\u29872 \u22659 \u22793 \u25968 \u12398 \u21462 \u24471  (Lambda\u35373 \u23450 \u12391 \u24517 \u35201 ) ---\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 try\cf4 \strokec4 :\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     USERS_TABLE_NAME \strokec6 =\strokec4  os.environ[\cf7 \strokec7 'USERS_TABLE_NAME'\cf4 \strokec4 ]\cb1 \
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 except\cf4 \strokec4  \cf8 \strokec8 KeyError\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     logger.error(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u29872 \u22659 \u22793 \u25968 \u12364 \u35373 \u23450 \u12373 \u12428 \u12390 \u12356 \u12414 \u12379 \u12435 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 raise\cf4 \strokec4  \cf8 \strokec8 Exception\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u29872 \u22659 \u22793 \u25968 \u12398 \u35373 \u23450 \u12456 \u12521 \u12540 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3 users_table \strokec6 =\strokec4  dynamodb.Table(USERS_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 def\cf4 \strokec4  \cf10 \strokec10 lambda_handler\cf4 \strokec4 (\cf11 \strokec11 event\cf4 \strokec4 , \cf11 \strokec11 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     logger.info(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u21463 \u20449 \u12452 \u12505 \u12531 \u12488 : \cf9 \strokec9 \{\cf4 \strokec4 event\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12518 \u12540 \u12470 \u12540 ID\u12398 \u21462 \u24471  (\u20363 : /users/\{userId\}/settings)\cf4 \cb1 \strokec4 \
\cb3         user_id \strokec6 =\strokec4  event.get(\cf7 \strokec7 'pathParameters'\cf4 \strokec4 , \{\}).get(\cf7 \strokec7 'userId'\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  user_id:\cb1 \
\cb3             logger.warning(\cf7 \strokec7 "\uc0\u12497 \u12473 \u12497 \u12521 \u12513 \u12540 \u12479 \u12395 userId\u12364 \u12354 \u12426 \u12414 \u12379 \u12435 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 400\cf4 \strokec4 , \cf7 \strokec7 "userId\uc0\u12364 \u24517 \u35201 \u12391 \u12377 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 # \uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12508 \u12487 \u12451 \u12363 \u12425 \u35373 \u23450 \u20516 \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         body \strokec6 =\strokec4  json.loads(event.get(\cf7 \strokec7 'body'\cf4 \strokec4 , \cf7 \strokec7 '\cf9 \strokec9 \{\}\cf7 \strokec7 '\cf4 \strokec4 ))\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # notifyOnDM \uc0\u12364 \u12508 \u12487 \u12451 \u12395 \u21547 \u12414 \u12428 \u12390 \u12356 \u12427 \u12363 \u12481 \u12455 \u12483 \u12463 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 'notifyOnDM'\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  \cf9 \strokec9 in\cf4 \strokec4  body \cf9 \strokec9 or\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  \cf10 \strokec10 isinstance\cf4 \strokec4 (body[\cf7 \strokec7 'notifyOnDM'\cf4 \strokec4 ], \cf8 \strokec8 bool\cf4 \strokec4 ):\cb1 \
\cb3             logger.warning(\cf7 \strokec7 "\uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12508 \u12487 \u12451 \u12395  notifyOnDM (boolean) \u12364 \u12354 \u12426 \u12414 \u12379 \u12435 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 400\cf4 \strokec4 , \cf7 \strokec7 "notifyOnDM (boolean\uc0\u22411 ) \u12364 \u24517 \u35201 \u12391 \u12377 "\cf4 \strokec4 )\cb1 \
\cb3             \cb1 \
\cb3         notify_on_dm \strokec6 =\strokec4  body[\cf7 \strokec7 'notifyOnDM'\cf4 \strokec4 ]\cb1 \
\
\cb3         logger.info(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u12518 \u12540 \u12470 \u12540  \cf9 \strokec9 \{\cf4 \strokec4 user_id\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12398  notifyOnDM \u12434  \cf9 \strokec9 \{\cf4 \strokec4 notify_on_dm\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12395 \u26356 \u26032 \u12375 \u12414 \u12377 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 # DynamoDB\uc0\u12398 UpdateItem\u12391 \u23646 \u24615 \u12434 \u26356 \u26032  (PUT)\cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             \cf5 \strokec5 # Users\uc0\u12486 \u12540 \u12502 \u12523 \u12398 \u12503 \u12521 \u12452 \u12510 \u12522 \u12461 \u12540 \u12364  'userId' \u12391 \u12354 \u12427 \u12371 \u12392 \u12434 \u21069 \u25552 \u12392 \u12375 \u12390 \u12356 \u12414 \u12377 \cf4 \cb1 \strokec4 \
\cb3             users_table.update_item(\cb1 \
\cb3                 \cf11 \strokec11 Key\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 'userId'\cf4 \strokec4 : user_id\},\cb1 \
\cb3                 \cf11 \strokec11 UpdateExpression\cf4 \strokec6 =\cf7 \strokec7 "SET #notifyOnDM = :val"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 ExpressionAttributeNames\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 '#notifyOnDM'\cf4 \strokec4 : \cf7 \strokec7 'notifyOnDM'\cf4 \strokec4 \},\cb1 \
\cb3                 \cf11 \strokec11 ExpressionAttributeValues\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 ':val'\cf4 \strokec4 : notify_on_dm\},\cb1 \
\cb3                 \cf11 \strokec11 ReturnValues\cf4 \strokec6 =\cf7 \strokec7 "UPDATED_NEW"\cf4 \cb1 \strokec4 \
\cb3             )\cb1 \
\cb3             logger.info(\cf9 \strokec9 f\cf7 \strokec7 "Users\uc0\u12486 \u12540 \u12502 \u12523 \u12434 \u26356 \u26032 \u12375 \u12414 \u12375 \u12383 : \cf9 \strokec9 \{\cf4 \strokec4 user_id\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf7 \strokec7 "message"\cf4 \strokec4 : \cf7 \strokec7 "\uc0\u35373 \u23450 \u12364 \u26356 \u26032 \u12373 \u12428 \u12414 \u12375 \u12383 "\cf4 \strokec4 , \cf7 \strokec7 "notifyOnDM"\cf4 \strokec4 : notify_on_dm\})\cb1 \
\
\cb3         \cf2 \strokec2 except\cf4 \strokec4  ClientError \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             logger.error(\cf9 \strokec9 f\cf7 \strokec7 "Users\uc0\u12486 \u12540 \u12502 \u12523 \u12398 \u26356 \u26032 \u12395 \u22833 \u25943 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 500\cf4 \strokec4 , \cf9 \strokec9 f\cf7 \strokec7 "DB\uc0\u26356 \u26032 \u12456 \u12521 \u12540 : \cf9 \strokec9 \{\cf4 \strokec4 e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Message'\cf4 \strokec4 ]\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3     \cf2 \strokec2 except\cf4 \strokec4  json.JSONDecodeError:\cb1 \
\cb3         logger.warning(\cf7 \strokec7 "\uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12508 \u12487 \u12451 \u12398 JSON\u12497 \u12540 \u12473 \u12395 \u22833 \u25943 \u12375 \u12414 \u12375 \u12383 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 400\cf4 \strokec4 , \cf7 \strokec7 "\uc0\u28961 \u21177 \u12394 JSON\u24418 \u24335 \u12391 \u12377 "\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf8 \strokec8 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         logger.error(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u20104 \u26399 \u12379 \u12396 \u12456 \u12521 \u12540 \u12364 \u30330 \u29983 \u12375 \u12414 \u12375 \u12383 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 , \cf11 \strokec11 exc_info\cf4 \strokec6 =\cf9 \strokec9 True\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 500\cf4 \strokec4 , \cf9 \strokec9 f\cf7 \strokec7 "\uc0\u20869 \u37096 \u12469 \u12540 \u12496 \u12540 \u12456 \u12521 \u12540 : \cf9 \strokec9 \{\cf8 \strokec8 str\cf4 \strokec4 (e)\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 def\cf4 \strokec4  \cf10 \strokec10 create_response\cf4 \strokec4 (\cf11 \strokec11 status_code\cf4 \strokec4 , \cf11 \strokec11 body\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf7 \strokec7 """API Gateway\uc0\u29992 \u12398 HTTP\u12524 \u12473 \u12509 \u12531 \u12473 \u12434 \u20316 \u25104 \u12377 \u12427 \u12504 \u12523 \u12497 \u12540 \u38306 \u25968 """\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3         \cf7 \strokec7 'statusCode'\cf4 \strokec4 : status_code,\cb1 \
\cb3         \cf7 \strokec7 'headers'\cf4 \strokec4 : \{\cb1 \
\cb3             \cf7 \strokec7 'Content-Type'\cf4 \strokec4 : \cf7 \strokec7 'application/json'\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'Access-Control-Allow-Origin'\cf4 \strokec4 : \cf7 \strokec7 '*'\cf4 \strokec4  \cf5 \strokec5 # \uc0\u24517 \u35201 \u12395 \u24540 \u12376 \u12390 CORS\u35373 \u23450 \u12434 \u35519 \u25972 \cf4 \cb1 \strokec4 \
\cb3         \},\cb1 \
\cb3         \cf7 \strokec7 'body'\cf4 \strokec4 : json.dumps(body)\cb1 \
\cb3     \}\cb1 \
}