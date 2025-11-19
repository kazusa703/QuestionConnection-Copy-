{\rtf1\ansi\ansicpg932\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red157\green0\blue210;\red255\green255\blue255;\red45\green45\blue45;
\red0\green0\blue0;\red144\green1\blue18;\red0\green0\blue255;\red101\green76\blue29;\red0\green0\blue109;
\red15\green112\blue1;\red19\green118\blue70;\red32\green108\blue135;}
{\*\expandedcolortbl;;\cssrgb\c68627\c0\c85882;\cssrgb\c100000\c100000\c100000;\cssrgb\c23137\c23137\c23137;
\cssrgb\c0\c0\c0;\cssrgb\c63922\c8235\c8235;\cssrgb\c0\c0\c100000;\cssrgb\c47451\c36863\c14902;\cssrgb\c0\c6275\c50196;
\cssrgb\c0\c50196\c0;\cssrgb\c3529\c52549\c34510;\cssrgb\c14902\c49804\c60000;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 import\cf4 \strokec4  json\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  boto3\cb1 \
\cf2 \cb3 \strokec2 import\cf4 \strokec4  uuid\cb1 \
\cf2 \cb3 \strokec2 from\cf4 \strokec4  datetime \cf2 \strokec2 import\cf4 \strokec4  datetime\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 dynamodb \strokec5 =\strokec4  boto3.resource(\cf6 \strokec6 'dynamodb'\cf4 \strokec4 )\cb1 \
\cb3 table \strokec5 =\strokec4  dynamodb.Table(\cf6 \strokec6 'AnswersLog'\cf4 \strokec4 )\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 def\cf4 \strokec4  \cf8 \strokec8 lambda_handler\cf4 \strokec4 (\cf9 \strokec9 event\cf4 \strokec4 , \cf9 \strokec9 context\cf4 \strokec4 ):\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf2 \strokec2 try\cf4 \strokec4 :\cb1 \
\cb3         body \strokec5 =\strokec4  json.loads(event[\cf6 \strokec6 'body'\cf4 \strokec4 ])\cb1 \
\
\cb3         \cf10 \strokec10 # \uc0\u24517 \u38920 \u38917 \u30446 \u12434 \u12481 \u12455 \u12483 \u12463 \cf4 \cb1 \strokec4 \
\cb3         required_fields \strokec5 =\strokec4  [\cf6 \strokec6 'questionId'\cf4 \strokec4 , \cf6 \strokec6 'userId'\cf4 \strokec4 , \cf6 \strokec6 'selectedChoiceId'\cf4 \strokec4 , \cf6 \strokec6 'isCorrect'\cf4 \strokec4 ]\cb1 \
\cb3         \cf2 \strokec2 if\cf4 \strokec4  \cf7 \strokec7 not\cf4 \strokec4  \cf8 \strokec8 all\cf4 \strokec4 (field \cf2 \strokec2 in\cf4 \strokec4  body \cf2 \strokec2 for\cf4 \strokec4  field \cf2 \strokec2 in\cf4 \strokec4  required_fields):\cb1 \
\cb3             \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3                 \cf6 \strokec6 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 400\cf4 \strokec4 ,\cb1 \
\cb3                 \cf6 \strokec6 'body'\cf4 \strokec4 : json.dumps(\{\cf6 \strokec6 'error'\cf4 \strokec4 : \cf6 \strokec6 'Missing required parameters'\cf4 \strokec4 \})\cb1 \
\cb3             \}\cb1 \
\
\cb3         item \strokec5 =\strokec4  \{\cb1 \
\cb3             \cf6 \strokec6 'logId'\cf4 \strokec4 : \cf12 \strokec12 str\cf4 \strokec4 (uuid.uuid4()), \cf10 \strokec10 # \uc0\u12518 \u12491 \u12540 \u12463 \u12394 ID\u12434 \u20027 \u12461 \u12540 \u12392 \u12375 \u12390 \u36861 \u21152 \cf4 \cb1 \strokec4 \
\cb3             \cf6 \strokec6 'questionId'\cf4 \strokec4 : body[\cf6 \strokec6 'questionId'\cf4 \strokec4 ],\cb1 \
\cb3             \cf6 \strokec6 'userId'\cf4 \strokec4 : body[\cf6 \strokec6 'userId'\cf4 \strokec4 ],\cb1 \
\cb3             \cf6 \strokec6 'selectedChoiceId'\cf4 \strokec4 : body[\cf6 \strokec6 'selectedChoiceId'\cf4 \strokec4 ],\cb1 \
\cb3             \cf6 \strokec6 'isCorrect'\cf4 \strokec4 : body[\cf6 \strokec6 'isCorrect'\cf4 \strokec4 ],\cb1 \
\cb3             \cf6 \strokec6 'timestamp'\cf4 \strokec4 : datetime.utcnow().isoformat() \strokec5 +\strokec4  \cf6 \strokec6 "Z"\cf4 \cb1 \strokec4 \
\cb3         \}\cb1 \
\
\cb3         table.put_item(\cf9 \strokec9 Item\cf4 \strokec5 =\strokec4 item)\cb1 \
\
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf6 \strokec6 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 201\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 'body'\cf4 \strokec4 : json.dumps(\{\cf6 \strokec6 'message'\cf4 \strokec4 : \cf6 \strokec6 'Answer logged successfully'\cf4 \strokec4 \})\cb1 \
\cb3         \}\cb1 \
\cb3     \cf2 \strokec2 except\cf4 \strokec4  \cf12 \strokec12 Exception\cf4 \strokec4  \cf2 \strokec2 as\cf4 \strokec4  e:\cb1 \
\cb3         \cf8 \strokec8 print\cf4 \strokec4 (\cf7 \strokec7 f\cf6 \strokec6 "Error: \cf7 \strokec7 \{\cf4 \strokec4 e\cf7 \strokec7 \}\cf6 \strokec6 "\cf4 \strokec4 )\cb1 \
\cb3         \cf2 \strokec2 return\cf4 \strokec4  \{\cb1 \
\cb3             \cf6 \strokec6 'statusCode'\cf4 \strokec4 : \cf11 \strokec11 500\cf4 \strokec4 ,\cb1 \
\cb3             \cf6 \strokec6 'body'\cf4 \strokec4 : json.dumps(\{\cf6 \strokec6 'error'\cf4 \strokec4 : \cf12 \strokec12 str\cf4 \strokec4 (e)\})\cb1 \
\cb3         \}\cb1 \
}