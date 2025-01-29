# /bin/bash

aws ecr get-login-password | docker login --username AWS --password-stdin ${REPO_URI}

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