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
\pard\pardeftab720\partightenfactor0
\cf2 \cb3 \strokec2 except\cf4 \strokec4  \cf8 \strokec8 KeyError\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     logger.error(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u29872 \u22659 \u22793 \u25968 \u12364 \u35373 \u23450 \u12373 \u12428 \u12390 \u12356 \u12414 \u12379 \u12435 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 raise\cf4 \strokec4  \cf8 \strokec8 Exception\cf4 \strokec4 (\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u29872 \u22659 \u22793 \u25968 \u12398 \u35373 \u23450 \u12456 \u12521 \u12540 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3 users_table \strokec6 =\strokec4  dynamodb.Table(USERS_TABLE_NAME)\cb1 \
\cb3 devices_table \strokec6 =\strokec4  dynamodb.Table(DEVICES_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf9 \cb3 \strokec9 def\cf4 \strokec4  \cf10 \strokec10 lambda_handler\cf4 \strokec4 (\cf11 \strokec11 event\cf4 \strokec4 , \cf11 \strokec11 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf5 \strokec5 # DM\uc0\u36865 \u20449 Lambda (\u12473 \u12486 \u12483 \u12503 5) \u12363 \u12425 \u28193 \u12373 \u12428 \u12383 \u12506 \u12452 \u12525 \u12540 \u12489 \cf4 \cb1 \strokec4 \
\cb3     logger.info(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u21463 \u20449 \u12452 \u12505 \u12531 \u12488 : \cf9 \strokec9 \{\cf4 \strokec4 event\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3     \cf5 \strokec5 # 1. \uc0\u12452 \u12505 \u12531 \u12488 \u12506 \u12452 \u12525 \u12540 \u12489 \u12398 \u35299 \u26512 \cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         recipient_user_id \strokec6 =\strokec4  event[\cf7 \strokec7 'recipientUserId'\cf4 \strokec4 ]\cb1 \
\cb3         sender_name \strokec6 =\strokec4  event[\cf7 \strokec7 'senderName'\cf4 \strokec4 ]\cb1 \
\cb3         message_excerpt \strokec6 =\strokec4  event[\cf7 \strokec7 'messageExcerpt'\cf4 \strokec4 ]\cb1 \
\cb3         thread_id \strokec6 =\strokec4  event[\cf7 \strokec7 'threadId'\cf4 \strokec4 ]\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf8 \strokec8 KeyError\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         logger.error(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u12506 \u12452 \u12525 \u12540 \u12489 \u12395 \u24517 \u35201 \u12394 \u12461 \u12540 \u12364 \u12354 \u12426 \u12414 \u12379 \u12435 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12522 \u12488 \u12521 \u12452 \u19981 \u21487 \u12398 \u12456 \u12521 \u12540 \u12290 \u12371 \u12371 \u12391 \u32066 \u20102 \u12290 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cf7 \strokec7 'status'\cf4 \strokec4 : \cf7 \strokec7 'error'\cf4 \strokec4 , \cf7 \strokec7 'message'\cf4 \strokec4 : \cf9 \strokec9 f\cf7 \strokec7 "Invalid payload: \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 \}\cb1 \
\
\cb3     \cf5 \strokec5 # 2. \uc0\u21463 \u20449 \u32773 \u12398 \u36890 \u30693 \u35373 \u23450  (notifyOnDM) \u12434 \u30906 \u35469 \cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         response \strokec6 =\strokec4  users_table.get_item(\cf11 \strokec11 Key\cf4 \strokec6 =\strokec4 \{\cf7 \strokec7 'userId'\cf4 \strokec4 : recipient_user_id\})\cb1 \
\cb3         user_item \strokec6 =\strokec4  response.get(\cf7 \strokec7 'Item'\cf4 \strokec4 )\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  user_item \cf9 \strokec9 or\cf4 \strokec4  user_item.get(\cf7 \strokec7 'notifyOnDM'\cf4 \strokec4 ) \cf9 \strokec9 is\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  \cf9 \strokec9 True\cf4 \strokec4 :\cb1 \
\cb3             \cf5 \strokec5 # \uc0\u12518 \u12540 \u12470 \u12540 \u12364 \u23384 \u22312 \u12375 \u12394 \u12356 \u12289 \u12414 \u12383 \u12399  notifyOnDM \u12364  false (\u12414 \u12383 \u12399 null)\cf4 \cb1 \strokec4 \
\cb3             logger.info(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u12518 \u12540 \u12470 \u12540  \cf9 \strokec9 \{\cf4 \strokec4 recipient_user_id\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12399 \u36890 \u30693 \u12364 \u12458 \u12501 \u12391 \u12377 \u12290 publishWillStop (notifyOnDM=false/null)"\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cf7 \strokec7 'status'\cf4 \strokec4 : \cf7 \strokec7 'stopped'\cf4 \strokec4 , \cf7 \strokec7 'reason'\cf4 \strokec4 : \cf7 \strokec7 'NotifyOnDM is false or not set'\cf4 \strokec4 \}\cb1 \
\cb3             \cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  ClientError \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         logger.error(\cf9 \strokec9 f\cf7 \strokec7 "Users\uc0\u12486 \u12540 \u12502 \u12523 \u12398 \u35501 \u12415 \u21462 \u12426 \u12395 \u22833 \u25943 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 # DB\uc0\u12456 \u12521 \u12540 \u12290 \u38750 \u21516 \u26399 \u21628 \u12403 \u20986 \u12375 \u12394 \u12398 \u12391 \u12289 AWS\u20596 \u12391 \u12522 \u12488 \u12521 \u12452 \u12373 \u12428 \u12427 \u12290 \cf4 \cb1 \strokec4 \
\cb3         \cf2 \strokec2 raise\cf4 \strokec4  e\cb1 \
\
\cb3     \cf5 \strokec5 # 3. \uc0\u21463 \u20449 \u32773 \u12398 \u12487 \u12496 \u12452 \u12473  (EndpointArn) \u12434 \u12377 \u12409 \u12390 \u21462 \u24471 \cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         \cf5 \strokec5 # Devices\uc0\u12486 \u12540 \u12502 \u12523 \u12398  'userId' (PK) \u12391 \u12463 \u12456 \u12522 \cf4 \cb1 \strokec4 \
\cb3         response \strokec6 =\strokec4  devices_table.query(\cb1 \
\cb3             \cf11 \strokec11 KeyConditionExpression\cf4 \strokec6 =\strokec4 boto3.dynamodb.conditions.Key(\cf7 \strokec7 'userId'\cf4 \strokec4 ).eq(recipient_user_id)\cb1 \
\cb3         )\cb1 \
\cb3         devices \strokec6 =\strokec4  response.get(\cf7 \strokec7 'Items'\cf4 \strokec4 , [])\cb1 \
\cb3         \cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  devices:\cb1 \
\cb3             logger.warning(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u12518 \u12540 \u12470 \u12540  \cf9 \strokec9 \{\cf4 \strokec4 recipient_user_id\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12398 \u30331 \u37682 \u12487 \u12496 \u12452 \u12473 \u12364 \u35211 \u12388 \u12363 \u12426 \u12414 \u12379 \u12435 \u12290 publishWillStop (noDevices)"\cf4 \strokec4 )\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cf7 \strokec7 'status'\cf4 \strokec4 : \cf7 \strokec7 'stopped'\cf4 \strokec4 , \cf7 \strokec7 'reason'\cf4 \strokec4 : \cf7 \strokec7 'No devices found'\cf4 \strokec4 \}\cb1 \
\cb3             \cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  ClientError \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         logger.error(\cf9 \strokec9 f\cf7 \strokec7 "Devices\uc0\u12486 \u12540 \u12502 \u12523 \u12398 Query\u12395 \u22833 \u25943 : \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 raise\cf4 \strokec4  e\cb1 \
\
\cb3     logger.info(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u12518 \u12540 \u12470 \u12540  \cf9 \strokec9 \{\cf4 \strokec4 recipient_user_id\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12398  \cf9 \strokec9 \{\cf10 \strokec10 len\cf4 \strokec4 (devices)\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u21488 \u12398 \u12487 \u12496 \u12452 \u12473 \u12395 \u36890 \u30693 \u12434 \u35430 \u12415 \u12414 \u12377 \u12290 publishAttempt"\cf4 \strokec4 )\cb1 \
\
\cb3     \cf5 \strokec5 # 4. APNs\uc0\u12506 \u12452 \u12525 \u12540 \u12489 \u12398 \u20316 \u25104  (iOS\u12463 \u12521 \u12452 \u12450 \u12531 \u12488 \u21521 \u12369 )\cf4 \cb1 \strokec4 \
\cb3     aps_payload \strokec6 =\strokec4  \{\cb1 \
\cb3         \cf7 \strokec7 'aps'\cf4 \strokec4 : \{\cb1 \
\cb3             \cf7 \strokec7 'alert'\cf4 \strokec4 : \{\cb1 \
\cb3                 \cf7 \strokec7 'title'\cf4 \strokec4 : \cf9 \strokec9 f\cf7 \strokec7 "\cf9 \strokec9 \{\cf4 \strokec4 sender_name\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12373 \u12435 \u12363 \u12425 \u12398 \u26032 \u30528 \u12513 \u12483 \u12475 \u12540 \u12472 "\cf4 \strokec4 ,\cb1 \
\cb3                 \cf7 \strokec7 'body'\cf4 \strokec4 : message_excerpt\cb1 \
\cb3             \},\cb1 \
\cb3             \cf7 \strokec7 'sound'\cf4 \strokec4 : \cf7 \strokec7 'default'\cf4 \strokec4 ,\cb1 \
\cb3             \cf5 \strokec5 # 'badge': 1  # (\uc0\u27880 \u65306 \u27491 \u30906 \u12394 \u12496 \u12483 \u12472 \u12459 \u12454 \u12531 \u12488 \u12399 \u21029 \u36884 \u31649 \u29702 \u12364 \u24517 \u35201 \u12394 \u12383 \u12417 \u12289 \u19968 \u26086 \u12467 \u12513 \u12531 \u12488 \u12450 \u12454 \u12488 \u12434 \u25512 \u22888 )\cf4 \cb1 \strokec4 \
\cb3         \},\cb1 \
\cb3         \cf5 \strokec5 # \uc0\u12459 \u12473 \u12479 \u12512 \u12487 \u12540 \u12479  (iOS\u12450 \u12503 \u12522 \u12364 \u36890 \u30693 \u21463 \u20449 \u26178 \u12395 \u21442 \u29031 \u12391 \u12365 \u12427 )\cf4 \cb1 \strokec4 \
\cb3         \cf7 \strokec7 'customData'\cf4 \strokec4 : \{\cb1 \
\cb3             \cf7 \strokec7 'type'\cf4 \strokec4 : \cf7 \strokec7 'DM'\cf4 \strokec4 ,\cb1 \
\cb3             \cf7 \strokec7 'threadId'\cf4 \strokec4 : thread_id\cb1 \
\cb3         \}\cb1 \
\cb3     \}\cb1 \
\cb3     \cb1 \
\cb3     \cf5 \strokec5 # SNS\uc0\u12395 \u36865 \u20449 \u12377 \u12427 \u12513 \u12483 \u12475 \u12540 \u12472 \u20840 \u20307  (APNS\u12461 \u12540 \u12391 \u12493 \u12473 \u12488 \u12377 \u12427 )\cf4 \cb1 \strokec4 \
\cb3     message_to_sns \strokec6 =\strokec4  \{\cb1 \
\cb3         \cf7 \strokec7 'default'\cf4 \strokec4 : \cf9 \strokec9 f\cf7 \strokec7 "\cf9 \strokec9 \{\cf4 \strokec4 sender_name\cf9 \strokec9 \}\cf7 \strokec7 : \cf9 \strokec9 \{\cf4 \strokec4 message_excerpt\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 , \cf5 \strokec5 # \uc0\u12501 \u12457 \u12540 \u12523 \u12496 \u12483 \u12463 \u29992 \cf4 \cb1 \strokec4 \
\cb3         \cf7 \strokec7 'APNS'\cf4 \strokec4 : json.dumps(aps_payload),\cb1 \
\cb3         \cf5 \strokec5 # 'APNS_SANDBOX': json.dumps(aps_payload) # (\uc0\u27880 : SNS\u12450 \u12503 \u12522 \u12399 \u26412 \u30058 \u29992  'APNS' \u12398 \u12415 \u12394 \u12398 \u12391 \u12289 \u12371 \u12428 \u12399 \u19981 \u35201 )\cf4 \cb1 \strokec4 \
\cb3     \}\cb1 \
\
\cb3     success_count \strokec6 =\strokec4  \cf12 \strokec12 0\cf4 \cb1 \strokec4 \
\cb3     failure_count \strokec6 =\strokec4  \cf12 \strokec12 0\cf4 \cb1 \strokec4 \
\
\cb3     \cf5 \strokec5 # 5. \uc0\u21508 \u12487 \u12496 \u12452 \u12473 \u12395 Publish\cf4 \cb1 \strokec4 \
\cb3     \cf2 \strokec2 for\cf4 \strokec4  device \cf2 \strokec2 in\cf4 \strokec4  devices:\cb1 \
\cb3         endpoint_arn \strokec6 =\strokec4  device.get(\cf7 \strokec7 'endpointArn'\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf9 \strokec9 not\cf4 \strokec4  endpoint_arn:\cb1 \
\cb3             logger.warning(\cf9 \strokec9 f\cf7 \strokec7 "\uc0\u12487 \u12496 \u12452 \u12473  \cf9 \strokec9 \{\cf4 \strokec4 device.get(\cf7 \strokec7 'deviceId'\cf4 \strokec4 )\cf9 \strokec9 \}\cf7 \strokec7  \uc0\u12395 endpointArn\u12364 \u12354 \u12426 \u12414 \u12379 \u12435 \u12290 \u12473 \u12461 \u12483 \u12503 \u12375 \u12414 \u12377 \u12290 "\cf4 \strokec4 )\cb1 \
\cb3             failure_count \strokec6 +=\strokec4  \cf12 \strokec12 1\cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 continue\cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3             sns.publish(\cb1 \
\cb3                 \cf11 \strokec11 TargetArn\cf4 \strokec6 =\strokec4 endpoint_arn,\cb1 \
\cb3                 \cf11 \strokec11 Message\cf4 \strokec6 =\strokec4 json.dumps(message_to_sns),\cb1 \
\cb3                 \cf11 \strokec11 MessageStructure\cf4 \strokec6 =\cf7 \strokec7 'json'\cf4 \cb1 \strokec4 \
\cb3             )\cb1 \
\cb3             logger.info(\cf9 \strokec9 f\cf7 \strokec7 "Publish\uc0\u25104 \u21151 : \cf9 \strokec9 \{\cf4 \strokec4 endpoint_arn\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             success_count \strokec6 +=\strokec4  \cf12 \strokec12 1\cf4 \cb1 \strokec4 \
\
\cb3         \cf2 \strokec2 except\cf4 \strokec4  ClientError \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3             error_code \strokec6 =\strokec4  e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Code'\cf4 \strokec4 ]\cb1 \
\cb3             logger.error(\cf9 \strokec9 f\cf7 \strokec7 "Publish\uc0\u22833 \u25943 : \cf9 \strokec9 \{\cf4 \strokec4 endpoint_arn\cf9 \strokec9 \}\cf7 \strokec7 , Error: \cf9 \strokec9 \{\cf4 \strokec4 e\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3             failure_count \strokec6 +=\strokec4  \cf12 \strokec12 1\cf4 \cb1 \strokec4 \
\cb3             \cb1 \
\cb3             \cf5 \strokec5 # --- \uc0\u36939 \u29992 \u30435 \u35222 \u29992 \u12398 \u12525 \u12464  (CloudWatch\u12513 \u12488 \u12522 \u12463 \u12473 \u12501 \u12451 \u12523 \u12479 \u12540 \u29992 ) ---\cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 if\cf4 \strokec4  error_code \strokec6 ==\strokec4  \cf7 \strokec7 'EndpointDisabled'\cf4 \strokec4 :\cb1 \
\cb3                 logger.error(\cf9 \strokec9 f\cf7 \strokec7 "PUBLISH_FAILED: EndpointDisabled: \cf9 \strokec9 \{\cf4 \strokec4 endpoint_arn\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3                 \cf5 \strokec5 # \cf9 \strokec9 TODO\cf5 \strokec5 : Endpoint\uc0\u12364 Disabled\u12398 \u22580 \u21512 \u12289 Devices\u12486 \u12540 \u12502 \u12523 \u12363 \u12425 \u12371 \u12398 \u12524 \u12467 \u12540 \u12489 \u12434 \u21066 \u38500 \u12377 \u12427 \u12525 \u12472 \u12483 \u12463 \u12434 \u12371 \u12371 \u12395 \u36861 \u21152 \u12375 \u12390 \u12418 \u12424 \u12356 \cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 elif\cf4 \strokec4  error_code \strokec6 ==\strokec4  \cf7 \strokec7 'InvalidParameter'\cf4 \strokec4  \cf9 \strokec9 and\cf4 \strokec4  \cf7 \strokec7 'Invalid token'\cf4 \strokec4  \cf9 \strokec9 in\cf4 \strokec4  e.response[\cf7 \strokec7 'Error'\cf4 \strokec4 ][\cf7 \strokec7 'Message'\cf4 \strokec4 ]:\cb1 \
\cb3                  \cf5 \strokec5 # \uc0\u12488 \u12540 \u12463 \u12531 \u12364 \u21476 \u12367 \u12394 \u12387 \u12383 \u22580 \u21512  (APNs\u12363 \u12425 \u25298 \u21542 )\cf4 \cb1 \strokec4 \
\cb3                 logger.error(\cf9 \strokec9 f\cf7 \strokec7 "PUBLISH_FAILED: InvalidProviderToken: \cf9 \strokec9 \{\cf4 \strokec4 endpoint_arn\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3                 \cf5 \strokec5 # \cf9 \strokec9 TODO\cf5 \strokec5 : Devices\uc0\u12486 \u12540 \u12502 \u12523 \u12363 \u12425 \u12371 \u12398 \u12524 \u12467 \u12540 \u12489 \u12434 \u21066 \u38500 \u12377 \u12427 \u12525 \u12472 \u12483 \u12463 \cf4 \cb1 \strokec4 \
\cb3             \cf2 \strokec2 else\cf4 \strokec4 :\cb1 \
\cb3                 logger.error(\cf9 \strokec9 f\cf7 \strokec7 "PUBLISH_FAILED: OtherError: \cf9 \strokec9 \{\cf4 \strokec4 error_code\cf9 \strokec9 \}\cf7 \strokec7  \cf9 \strokec9 \{\cf4 \strokec4 endpoint_arn\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\
\cb3     logger.info(\cf9 \strokec9 f\cf7 \strokec7 "Publish\uc0\u23436 \u20102 : success=\cf9 \strokec9 \{\cf4 \strokec4 success_count\cf9 \strokec9 \}\cf7 \strokec7 , failure=\cf9 \strokec9 \{\cf4 \strokec4 failure_count\cf9 \strokec9 \}\cf7 \strokec7 "\cf4 \strokec4 )\cb1 \
\cb3     \cf2 \strokec2 return\cf4 \strokec4  \{\cf7 \strokec7 'status'\cf4 \strokec4 : \cf7 \strokec7 'completed'\cf4 \strokec4 , \cf7 \strokec7 'success'\cf4 \strokec4 : success_count, \cf7 \strokec7 'failure'\cf4 \strokec4 : failure_count\}\cb1 \
}