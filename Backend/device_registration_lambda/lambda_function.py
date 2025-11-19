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
\cf2 \cb3 \strokec2 from\cf4 \strokec4  datetime \cf2 \strokec2 import\cf4 \strokec4  datetime\cb1 \
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
\cf4 \cb3 sns \strokec6 =\strokec4  boto3.client(\cf7 \strokec7 'sns'\cf4 \strokec4 )\cb1 \
\cb3 dynamodb \strokec6 =\strokec4  boto3.resource(\cf7 \strokec7 'dynamodb'\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 # --- \uc0\u29872 \u22659 \u22793 \u25968 \u12398 \u21462 \u24471  (Lambda\u35373 \u23450 \u12391 \u24517 \u35201 ) ---\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 try\cf4 \strokec4 :\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     USERS_TABLE_NAME \strokec6 =\strokec4  os.environ[\cf7 \strokec7 'USERS_TABLE_NAME'\cf4 \strokec4 ]\cb1 \
\cb3     DEVICES_TABLE_NAME \strokec6 =\strokec4  os.environ[\cf7 \strokec7 'DEVICES_TABLE_NAME'\cf4 \strokec4 ]\cb1 \
\cb3     SNS_PLATFORM_APP_ARN \strokec6 =\strokec4  os.environ[\cf7 \strokec7 'SNS_PLATFORM_APP_ARN'\cf4 \strokec4 ]\cb1 \
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 except\cf4 \strokec4  \cf8 \strokec8 KeyError\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     logger.error(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u29872 \u22659 \u22793 \u25968 \u12364 \u35373 \u23450 \u12373 \u12428 \u12390 \u12356 \u12414 \u12379 \u12435 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3     \cf5 \strokec5 # \uc0\u12371 \u12398 Lambda\u12399 \u36215 \u21205 \u26178 \u12395 \u22833 \u25943 \u12377 \u12427 \u12383 \u12417 \u12289 \u35373 \u23450 \u12511 \u12473 \u12398 \u26089 \u26399 \u30330 \u35211 \u12395 \u24441 \u31435 \u12388 \cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 raise\cf4 \strokec4  \cf8 \strokec8 Exception\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u29872 \u22659 \u22793 \u25968 \u12398 \u35373 \u23450 \u12456 \u12521 \u12540 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3 users_table \strokec6 =\strokec4  dynamodb.Table(USERS_TABLE_NAME)\cb1 \
\cb3 devices_table \strokec6 =\strokec4  dynamodb.Table(DEVICES_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 def\cf4 \strokec4  \cf10 \strokec10 lambda_handler\cf4 \strokec4 (\cf11 \strokec11 event\cf4 \strokec4 , \cf11 \strokec11 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     logger.info(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u21463 \u20449 \u12452 \u12505 \u12531 \u12488 : \cf9 \strokec9 \{\cf4 \strokec4 event\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf5 \strokec5 # API Gateway (HTTP API payload v2.0) \uc0\u12434 \u24819 \u23450 \cf4 \cb1 \strokec4 \
\cb3         \cf5 \strokec5 # v1.0 (REST API) \uc0\u12398 \u22580 \u21512 \u12399  'pathParameters' \u12420  'body' \u12398 \u27083 \u36896 \u12364 \u30064 \u12394 \u12426 \u12414 \u12377 \cf4 \cb1 \strokec4 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12518 \u12540 \u12470 \u12540 ID\u12398 \u21462 \u24471  (\u20363 : /users/\{userId\}/devices)\cf4 \cb1 \strokec4 \
\cb3         user_id \strokec6 =\strokec4  event.get(\cf7 \strokec7 'pathParameters'\cf4 \strokec4 , \{\}).get(\cf7 \strokec7 'userId'\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  user_id:\cb1 \
\cb3             logger.warning(\cf7 \strokec7 "\uc0\u12497 \u12473 \u12497 \u12521 \u12513 \u12540 \u12479 \u12395 userId\u12364 \u12354 \u12426 \u12414 \u12379 \u12435 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 400\cf4 \strokec4 , \cf7 \strokec7 "userId\uc0\u12364 \u24517 \u35201 \u12391 \u12377 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 # \uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12508 \u12487 \u12451 \u12363 \u12425 \u12487 \u12496 \u12452 \u12473 \u12488 \u12540 \u12463 \u12531 \u12434 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3         body \strokec6 =\strokec4  json.loads(event.get(\cf7 \strokec7 'body'\cf4 \strokec4 , \cf7 \strokec7 '\cf9 \strokec9 \{\}\cf7 \strokec7 '\cf4 \strokec4 ))\cb1 \
\cb3         device_token \strokec6 =\strokec4  body.get(\cf7 \strokec7 'deviceToken'\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  device_token:\cb1 \
\cb3             logger.warning(\cf7 \strokec7 "\uc0\u12522 \u12463 \u12456 \u12473 \u12488 \u12508 \u12487 \u12451 \u12395 deviceToken\u12364 \u12354 \u12426 \u12414 \u12379 \u12435 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 400\cf4 \strokec4 , \cf7 \strokec7 "deviceToken\uc0\u12364 \u24517 \u35201 \u12391 \u12377 "\cf4 \strokec4 )\cb1 \
\
\cb3         logger.info(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u12518 \u12540 \u12470 \u12540  \cf9 \strokec9 \{\cf4 \strokec4 user_id\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12398 \u12487 \u12496 \u12452 \u12473  \cf9 \strokec9 \{\cf4 \strokec4 device_token[:\cf12 \strokec12 10\cf4 \strokec4 ]\cf9 \strokec9 \}\cf7 \strokec7 ... \uc0\u12434 \u30331 \u37682 \u12375 \u12414 \u12377 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 # 1. SNS Platform Endpoint\uc0\u12398 \u20316 \u25104 \u12414 \u12383 \u12399 \u26356 \u26032 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             response \strokec6 =\strokec4  sns.create_platform_endpoint(\cb1 \
\cb3                 \cf11 \strokec11 PlatformApplicationArn\cf4 \strokec6 =\strokec4 SNS_PLATFORM_APP_ARN,\cb1 \
\cb3                 \cf11 \strokec11 Token\cf4 \strokec6 =\strokec4 device_token,\cb1 \
\cb3                 \cf11 \strokec11 Attributes\cf4 \strokec6 =\strokec4 \{\cb1 \
\cb3                     \cf7 \strokec7 'Enabled'\cf4 \strokec4 : \cf7 \strokec7 'true'\cf4 \cb1 \strokec4 \
\cb3                 \}\cb1 \
\cb3             )\cb1 \
\cb3             endpoint_arn \strokec6 =\strokec4  response[\cf7 \strokec7 'EndpointArn'\cf4 \strokec4 ]\cb1 \
\cb3             logger.info(\cf9 \strokec9 f\cf7 \strokec7 "SNS\uc0\u12456 \u12531 \u12489 \u12509 \u12452 \u12531 \u12488 \u12434 \u20316 \u25104 /\u26356 \u26032 \u12375 \u12414 \u12375 \u12383 : \cf9 \strokec9 \{\cf4 \strokec4 endpoint_arn\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf2 \strokec2 except\cf4 \strokec4  ClientError \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             \cf5 \strokec5 # \uc0\u12488 \u12540 \u12463 \u12531 \u12364 \u28961 \u21177 \u12394 \u22580 \u21512 \u12394 \u12393 \u12398 \u12495 \u12531 \u12489 \u12522 \u12531 \u12464 \cf4 \cb1 \strokec4 \
\cb3             logger.error(\cf9 \strokec9 f\cf7 \strokec7 "SNS\uc0\u12456 \u12531 \u12489 \u12509 \u12452 \u12531 \u12488 \u20316 \u25104 \u12395 \u22833 \u25943 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 500\cf4 \strokec4 , \cf9 \strokec9 f\cf7 \strokec7 "SNS\uc0\u12456 \u12531 \u12489 \u12509 \u12452 \u12531 \u12488 \u20316 \u25104 \u12456 \u12521 \u12540 : \cf9 \strokec9 \{\cf4 \strokec4 e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Message'\cf4 \strokec4 ]\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 # 2. Devices\uc0\u12486 \u12540 \u12502 \u12523 \u12395 \u24773 \u22577 \u12434 \u20445 \u23384 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             devices_table.put_item(\cb1 \
\cb3                 \cf11 \strokec11 Item\cf4 \strokec6 =\strokec4 \{\cb1 \
\cb3                     \cf7 \strokec7 'userId'\cf4 \strokec4 : user_id,\cb1 \
\cb3                     \cf7 \strokec7 'deviceId'\cf4 \strokec4 : device_token, \cf5 \strokec5 # deviceToken\uc0\u12434 SK\u12392 \u12375 \u12390 \u20351 \u29992 \cf4 \cb1 \strokec4 \
\cb3                     \cf7 \strokec7 'endpointArn'\cf4 \strokec4 : endpoint_arn,\cb1 \
\cb3                     \cf7 \strokec7 'updatedAt'\cf4 \strokec4 : datetime.utcnow().isoformat()\cb1 \
\cb3                 \}\cb1 \
\cb3             )\cb1 \
\cb3             logger.info(\cf9 \strokec9 f\cf7 \strokec7 "Devices\uc0\u12486 \u12540 \u12502 \u12523 \u12395 \u20445 \u23384 \u12375 \u12414 \u12375 \u12383 : userId=\cf9 \strokec9 \{\cf4 \strokec4 user_id\cf9 \strokec9 \}\cf7 \strokec7 , deviceId=\cf9 \strokec9 \{\cf4 \strokec4 device_token[:\cf12 \strokec12 10\cf4 \strokec4 ]\cf9 \strokec9 \}\cf7 \strokec7 ..."\cf4 \strokec4 )\cb1 \
\cb3             \cb1 \
\cb3         \cf2 \strokec2 except\cf4 \strokec4  ClientError \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             logger.error(\cf9 \strokec9 f\cf7 \strokec7 "Devices\uc0\u12486 \u12540 \u12502 \u12523 \u12408 \u12398 \u20445 \u23384 \u12395 \u22833 \u25943 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 500\cf4 \strokec4 , \cf9 \strokec9 f\cf7 \strokec7 "DB\uc0\u20445 \u23384 \u12456 \u12521 \u12540 : \cf9 \strokec9 \{\cf4 \strokec4 e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Message'\cf4 \strokec4 ]\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 # 3. (\uc0\u12458 \u12503 \u12471 \u12519 \u12531 ) Users\u12486 \u12540 \u12502 \u12523 \u12395  notifyOnDM \u12364 \u12394 \u12356 \u22580 \u21512 \u12289 \u12487 \u12501 \u12457 \u12523 \u12488 \u20516 \u12434 \u36861 \u21152 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             \cf5 \strokec5 # Users\uc0\u12486 \u12540 \u12502 \u12523 \u12398 \u12503 \u12521 \u12452 \u12510 \u12522 \u12461 \u12540 \u12364  'userId' \u12391 \u12354 \u12427 \u12371 \u12392 \u12434 \u21069 \u25552 \u12392 \u12375 \u12390 \u12356 \u12414 \u12377 \cf4 \cb1 \strokec4 \
\cb3             users_table.update_item(\cb1 \
\cb3                 \cf11 \strokec11 Key\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 'userId'\cf4 \strokec4 : user_id\}, \cb1 \
\cb3                 \cf11 \strokec11 UpdateExpression\cf4 \strokec6 =\cf7 \strokec7 "SET #notifyOnDM = if_not_exists(#notifyOnDM, :defaultValue)"\cf4 \strokec4 ,\cb1 \
\cb3                 \cf11 \strokec11 ExpressionAttributeNames\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 '#notifyOnDM'\cf4 \strokec4 : \cf7 \strokec7 'notifyOnDM'\cf4 \strokec4 \},\cb1 \
\cb3                 \cf11 \strokec11 ExpressionAttributeValues\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 ':defaultValue'\cf4 \strokec4 : \cf9 \strokec9 False\cf4 \strokec4 \}\cb1 \
\cb3             )\cb1 \
\cb3             logger.info(\cf9 \strokec9 f\cf7 \strokec7 "Users\uc0\u12486 \u12540 \u12502 \u12523 \u12398 notifyOnDM\u12487 \u12501 \u12457 \u12523 \u12488 \u20516 \u12434 \u35373 \u23450 \u30906 \u35469 \u12375 \u12414 \u12375 \u12383 : \cf9 \strokec9 \{\cf4 \strokec4 user_id\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 except\cf4 \strokec4  ClientError \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             \cf5 \strokec5 # Users\uc0\u12486 \u12540 \u12502 \u12523 \u12364 \u23384 \u22312 \u12375 \u12394 \u12356 \u12289 \u12414 \u12383 \u12399 PK\u12364 \u30064 \u12394 \u12427 \u22580 \u21512 \u12394 \u12393 \cf4 \cb1 \strokec4 \
\cb3             logger.warning(\cf9 \strokec9 f\cf7 \strokec7 "Users\uc0\u12486 \u12540 \u12502 \u12523 \u12398 \u12487 \u12501 \u12457 \u12523 \u12488 \u20516 \u35373 \u23450 \u12395 \u22833 \u25943 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             \cf5 \strokec5 # \uc0\u12487 \u12496 \u12452 \u12473 \u30331 \u37682 \u33258 \u20307 \u12399 \u25104 \u21151 \u12375 \u12390 \u12356 \u12427 \u12398 \u12391 \u12289 \u12371 \u12371 \u12391 \u12399 \u12456 \u12521 \u12540 \u12434 \u36820 \u12373 \u12394 \u12356 \cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 return\cf4 \strokec4  create_response(\cf12 \strokec12 200\cf4 \strokec4 , \{\cf7 \strokec7 "message"\cf4 \strokec4 : \cf7 \strokec7 "\uc0\u12487 \u12496 \u12452 \u12473 \u12364 \u27491 \u24120 \u12395 \u30331 \u37682 \u12373 \u12428 \u12414 \u12375 \u12383 "\cf4 \strokec4 , \cf7 \strokec7 "endpointArn"\cf4 \strokec4 : endpoint_arn\})\cb1 \
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