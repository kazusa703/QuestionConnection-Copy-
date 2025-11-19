{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red15\green112\blue1;\red255\green255\blue255;\red45\green45\blue45;
\red157\green0\blue210;\red0\green0\blue255;\red32\green108\blue135;\red101\green76\blue29;\red0\green0\blue109;
\red0\green0\blue0;\red19\green118\blue70;\red144\green1\blue18;}
{\*\expandedcolortbl;;\cssrgb\c0\c50196\c0;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c68627\c0\c85882;\cssrgb\c0\c0\c100000;\cssrgb\c14902\c49804\c60000;\cssrgb\c47451\c36863\c14902;\cssrgb\c0\c6275\c50196;
\cssrgb\c0\c0\c0;\cssrgb\c3529\c52549\c34510;\cssrgb\c63922\c8235\c8235;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 # lambda_function.py for updateUserSettingsFunction\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 import\cf4 \strokec4  json\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  boto3\cb1 \
\cf5 \cb3 \strokec5 import\cf4 \strokec4  os\cb1 \
\cf5 \cb3 \strokec5 from\cf4 \strokec4  botocore.exceptions \cf5 \strokec5 import\cf4 \strokec4  ClientError\cb1 \
\cf5 \cb3 \strokec5 from\cf4 \strokec4  decimal \cf5 \strokec5 import\cf4 \strokec4  Decimal\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 class\cf4 \strokec4  \cf7 \strokec7 DecimalEncoder\cf4 \strokec4 (\cf7 \strokec7 json\cf4 \strokec4 .\cf7 \strokec7 JSONEncoder\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf6 \strokec6 def\cf4 \strokec4  \cf8 \strokec8 default\cf4 \strokec4 (\cf9 \strokec9 self\cf4 \strokec4 , \cf9 \strokec9 o\cf4 \strokec4 ):\cb1 \
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf8 \strokec8 isinstance\cf4 \strokec4 (o, Decimal):\cb1 \
\cb3             \cf5 \strokec5 return\cf4 \strokec4  \cf7 \strokec7 int\cf4 \strokec4 (o) \cf5 \strokec5 if\cf4 \strokec4  o \strokec10 %\strokec4  \cf11 \strokec11 1\cf4 \strokec4  \strokec10 ==\strokec4  \cf11 \strokec11 0\cf4 \strokec4  \cf5 \strokec5 else\cf4 \strokec4  \cf7 \strokec7 float\cf4 \strokec4 (o)\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \cf7 \strokec7 super\cf4 \strokec4 (DecimalEncoder, \cf6 \strokec6 self\cf4 \strokec4 ).default(o)\cb1 \
\
\cb3 dynamodb \strokec10 =\strokec4  boto3.resource(\cf12 \strokec12 'dynamodb'\cf4 \strokec4 )\cb1 \
\cb3 USERS_TABLE_NAME \strokec10 =\strokec4  os.environ.get(\cf12 \strokec12 'USERS_TABLE_NAME'\cf4 \strokec4 , \cf12 \strokec12 'Users'\cf4 \strokec4 )\cb1 \
\cb3 users_table \strokec10 =\strokec4  dynamodb.Table(USERS_TABLE_NAME)\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 def\cf4 \strokec4  \cf8 \strokec8 lambda_handler\cf4 \strokec4 (\cf9 \strokec9 event\cf4 \strokec4 , \cf9 \strokec9 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Received event: \cf6 \strokec6 \{\cf4 \strokec4 json.dumps(event)\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 ) \cb1 \
\
\cb3     \cf5 \strokec5 try\cf4 \strokec4 :\cb1 \
\cb3         path_params \strokec10 =\strokec4  event.get(\cf12 \strokec12 'pathParameters'\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf6 \strokec6 not\cf4 \strokec4  path_params \cf6 \strokec6 or\cf4 \strokec4  \cf12 \strokec12 'userId'\cf4 \strokec4  \cf6 \strokec6 not\cf4 \strokec4  \cf6 \strokec6 in\cf4 \strokec4  path_params:\cb1 \
\cb3             \cf5 \strokec5 raise\cf4 \strokec4  \cf7 \strokec7 ValueError\cf4 \strokec4 (\cf12 \strokec12 "Missing 'userId' in path parameters"\cf4 \strokec4 )\cb1 \
\cb3         user_id \strokec10 =\strokec4  path_params[\cf12 \strokec12 'userId'\cf4 \strokec4 ]\cb1 \
\cb3         \cb1 \
\cb3         \cf5 \strokec5 try\cf4 \strokec4 :\cb1 \
\cb3             authenticated_user_id \strokec10 =\strokec4  event[\cf12 \strokec12 'requestContext'\cf4 \strokec4 ][\cf12 \strokec12 'authorizer'\cf4 \strokec4 ][\cf12 \strokec12 'claims'\cf4 \strokec4 ][\cf12 \strokec12 'sub'\cf4 \strokec4 ]\cb1 \
\cb3             \cf5 \strokec5 if\cf4 \strokec4  user_id \strokec10 !=\strokec4  authenticated_user_id:\cb1 \
\cb3                 \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Forbidden: Authenticated user \cf6 \strokec6 \{\cf4 \strokec4 authenticated_user_id\cf6 \strokec6 \}\cf12 \strokec12  cannot update settings for \cf6 \strokec6 \{\cf4 \strokec4 user_id\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\cb3                 \cf5 \strokec5 return\cf4 \strokec4  \{\cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 403\cf4 \strokec4 , \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(\{\cf12 \strokec12 'error'\cf4 \strokec4 : \cf12 \strokec12 'Forbidden'\cf4 \strokec4 \})\}\cb1 \
\cb3         \cf5 \strokec5 except\cf4 \strokec4  \cf7 \strokec7 KeyError\cf4 \strokec4 :\cb1 \
\cb3             \cf8 \strokec8 print\cf4 \strokec4 (\cf12 \strokec12 "Warning: Could not verify authenticated user. Check Cognito Authorizer setup."\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf6 \strokec6 not\cf4 \strokec4  event.get(\cf12 \strokec12 'body'\cf4 \strokec4 ):\cb1 \
\cb3             \cf5 \strokec5 raise\cf4 \strokec4  \cf7 \strokec7 ValueError\cf4 \strokec4 (\cf12 \strokec12 "Missing request body"\cf4 \strokec4 )\cb1 \
\cb3         body \strokec10 =\strokec4  json.loads(event.get(\cf12 \strokec12 'body'\cf4 \strokec4 ))\cb1 \
\cb3         \cb1 \
\cb3         update_expressions \strokec10 =\strokec4  []\cb1 \
\cb3         expression_attribute_values \strokec10 =\strokec4  \{\}\cb1 \
\cb3         expression_attribute_names \strokec10 =\strokec4  \{\}\cb1 \
\
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf12 \strokec12 'notifyOnCorrectAnswer'\cf4 \strokec4  \cf6 \strokec6 in\cf4 \strokec4  body:\cb1 \
\cb3             \cf2 \strokec2 # \uc0\u9733 \u9733 \u9733  \u20462 \u27491 : body.get('notifyOnCorrectAnswer', False) \u12398 \u12424 \u12358 \u12395 \u12487 \u12501 \u12457 \u12523 \u12488 \u20516 \u12434 \u25351 \u23450  \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\cb3             setting_correct \strokec10 =\strokec4  body.get(\cf12 \strokec12 'notifyOnCorrectAnswer'\cf4 \strokec4 , \cf6 \strokec6 False\cf4 \strokec4 ) \cb1 \
\cb3             \cf5 \strokec5 if\cf4 \strokec4  \cf6 \strokec6 not\cf4 \strokec4  \cf8 \strokec8 isinstance\cf4 \strokec4 (setting_correct, \cf7 \strokec7 bool\cf4 \strokec4 ):\cb1 \
\cb3                 \cf5 \strokec5 raise\cf4 \strokec4  \cf7 \strokec7 ValueError\cf4 \strokec4 (\cf12 \strokec12 "'notifyOnCorrectAnswer' must be a boolean (true or false)"\cf4 \strokec4 )\cb1 \
\cb3             \cb1 \
\cb3             update_expressions.append(\cf12 \strokec12 "#notifyCorrect = :valCorrect"\cf4 \strokec4 )\cb1 \
\cb3             expression_attribute_names[\cf12 \strokec12 "#notifyCorrect"\cf4 \strokec4 ] \strokec10 =\strokec4  \cf12 \strokec12 "notifyOnCorrectAnswer"\cf4 \cb1 \strokec4 \
\cb3             expression_attribute_values[\cf12 \strokec12 ":valCorrect"\cf4 \strokec4 ] \strokec10 =\strokec4  setting_correct\cb1 \
\cb3             \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Found setting: notifyOnCorrectAnswer = \cf6 \strokec6 \{\cf4 \strokec4 setting_correct\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf12 \strokec12 'notifyOnDM'\cf4 \strokec4  \cf6 \strokec6 in\cf4 \strokec4  body:\cb1 \
\cb3             \cf2 \strokec2 # \uc0\u9733 \u9733 \u9733  \u20462 \u27491 : body.get('notifyOnDM', False) \u12398 \u12424 \u12358 \u12395 \u12487 \u12501 \u12457 \u12523 \u12488 \u20516 \u12434 \u25351 \u23450  \u9733 \u9733 \u9733 \cf4 \cb1 \strokec4 \
\cb3             setting_dm \strokec10 =\strokec4  body.get(\cf12 \strokec12 'notifyOnDM'\cf4 \strokec4 , \cf6 \strokec6 False\cf4 \strokec4 ) \cb1 \
\cb3             \cf5 \strokec5 if\cf4 \strokec4  \cf6 \strokec6 not\cf4 \strokec4  \cf8 \strokec8 isinstance\cf4 \strokec4 (setting_dm, \cf7 \strokec7 bool\cf4 \strokec4 ):\cb1 \
\cb3                 \cf5 \strokec5 raise\cf4 \strokec4  \cf7 \strokec7 ValueError\cf4 \strokec4 (\cf12 \strokec12 "'notifyOnDM' must be a boolean (true or false)"\cf4 \strokec4 )\cb1 \
\cb3             \cb1 \
\cb3             update_expressions.append(\cf12 \strokec12 "#notifyDM = :valDM"\cf4 \strokec4 )\cb1 \
\cb3             expression_attribute_names[\cf12 \strokec12 "#notifyDM"\cf4 \strokec4 ] \strokec10 =\strokec4  \cf12 \strokec12 "notifyOnDM"\cf4 \cb1 \strokec4 \
\cb3             expression_attribute_values[\cf12 \strokec12 ":valDM"\cf4 \strokec4 ] \strokec10 =\strokec4  setting_dm\cb1 \
\cb3             \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Found setting: notifyOnDM = \cf6 \strokec6 \{\cf4 \strokec4 setting_dm\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 if\cf4 \strokec4  \cf6 \strokec6 not\cf4 \strokec4  update_expressions:\cb1 \
\cb3             \cf5 \strokec5 raise\cf4 \strokec4  \cf7 \strokec7 ValueError\cf4 \strokec4 (\cf12 \strokec12 "Missing 'notifyOnCorrectAnswer' or 'notifyOnDM' in request body"\cf4 \strokec4 )\cb1 \
\
\cb3         update_expression_str \strokec10 =\strokec4  \cf12 \strokec12 "SET "\cf4 \strokec4  \strokec10 +\strokec4  \cf12 \strokec12 ", "\cf4 \strokec4 .join(update_expressions)\cb1 \
\cb3         \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Updating settings for user: \cf6 \strokec6 \{\cf4 \strokec4 user_id\cf6 \strokec6 \}\cf12 \strokec12 . Expression: \cf6 \strokec6 \{\cf4 \strokec4 update_expression_str\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\
\cb3         users_table.update_item(\cb1 \
\cb3             \cf9 \strokec9 Key\cf4 \strokec10 =\strokec4 \{\cf12 \strokec12 'userId'\cf4 \strokec4 : user_id\},\cb1 \
\cb3             \cf9 \strokec9 UpdateExpression\cf4 \strokec10 =\strokec4 update_expression_str,\cb1 \
\cb3             \cf9 \strokec9 ExpressionAttributeNames\cf4 \strokec10 =\strokec4 expression_attribute_names,\cb1 \
\cb3             \cf9 \strokec9 ExpressionAttributeValues\cf4 \strokec10 =\strokec4 expression_attribute_values\cb1 \
\cb3         )\cb1 \
\cb3         \cf8 \strokec8 print\cf4 \strokec4 (\cf12 \strokec12 "User settings updated successfully."\cf4 \strokec4 )\cb1 \
\
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 200\cf4 \strokec4 , \cb1 \
\cb3             \cf12 \strokec12 'headers'\cf4 \strokec4 : \{ \cf12 \strokec12 'Content-Type'\cf4 \strokec4 : \cf12 \strokec12 'application/json'\cf4 \strokec4  \},\cb1 \
\cb3             \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(\{\cf12 \strokec12 'message'\cf4 \strokec4 : \cf12 \strokec12 'Settings updated successfully.'\cf4 \strokec4 \}, \cf9 \strokec9 cls\cf4 \strokec10 =\strokec4 DecimalEncoder)\cb1 \
\cb3         \}\cb1 \
\
\cb3     \cf5 \strokec5 except\cf4 \strokec4  ClientError \cf5 \strokec5 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "DynamoDB Error: \cf6 \strokec6 \{\cf4 \strokec4 e.response[\cf12 \strokec12 'Error'\cf4 \strokec4 ][\cf12 \strokec12 'Message'\cf4 \strokec4 ]\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 500\cf4 \strokec4 , \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(\{\cf12 \strokec12 'error'\cf4 \strokec4 : \cf7 \strokec7 str\cf4 \strokec4 (e)\})\}\cb1 \
\cb3     \cf5 \strokec5 except\cf4 \strokec4  \cf7 \strokec7 ValueError\cf4 \strokec4  \cf5 \strokec5 as\cf4 \strokec4  ve: \cb1 \
\cb3         \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Value Error: \cf6 \strokec6 \{\cf4 \strokec4 ve\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 400\cf4 \strokec4 , \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(\{\cf12 \strokec12 'error'\cf4 \strokec4 : \cf7 \strokec7 str\cf4 \strokec4 (ve)\})\}\cb1 \
\cb3     \cf5 \strokec5 except\cf4 \strokec4  \cf7 \strokec7 Exception\cf4 \strokec4  \cf5 \strokec5 as\cf4 \strokec4  e: \cb1 \
\cb3         \cf8 \strokec8 print\cf4 \strokec4 (\cf6 \strokec6 f\cf12 \strokec12 "Unexpected Error: \cf6 \strokec6 \{\cf4 \strokec4 e\cf6 \strokec6 \}\cf12 \strokec12 "\cf4 \strokec4 )\cb1 \
\cb3         \cf5 \strokec5 return\cf4 \strokec4  \{\cf12 \strokec12 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 500\cf4 \strokec4 , \cf12 \strokec12 'body'\cf4 \strokec4 : json.dumps(\{\cf12 \strokec12 'error'\cf4 \strokec4 : \cf7 \strokec7 str\cf4 \strokec4 (e)\})\}\cb1 \
}