 
 
 helm install falcon-kac crowdstrike/falcon-kac \
  -n falcon-kac --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set image.repository=$KAC_IMAGE_REPO \
  --set image.tag=$KAC_IMAGE_TAG