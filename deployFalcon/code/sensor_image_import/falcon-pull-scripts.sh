# /bin/bash

aws ecr get-login-password | docker login --username AWS --password-stdin 121607361004.dkr.ecr.us-east-1.amazonaws.com

./falcon-container-sensor-pull.sh \
-u $FALCON_CLIENT_ID \
-s $FALCON_CLIENT_SECRET \
-f $FALCON_CID \
-r $CS_CLOUD \
-t falcon-sensor \
-c $REPO_URI

./falcon-container-sensor-pull.sh \
-u $FALCON_CLIENT_ID \
-s $FALCON_CLIENT_SECRET \
-f $FALCON_CID \
-r $CS_CLOUD \
-t falcon-kac \
-c $REPO_URI