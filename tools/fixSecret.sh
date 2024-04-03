#-----------------------------------#
#  Secret Repair tool  #
#-----------------------------------#

# If the Secrets Manager secret and related paramaters are entered incorrectly, CodeBuild jobs will fail. Use this script to set things right

AWS_REGION='us-east-1'
   echo 
   echo "You will asked to provide a Falcon API Key Client ID and Secret." 
   echo "You can create one at https://falcon.crowdstrike.com/support/api-clients-and-keys"
   echo
   read -p "Enter your Falcon API Key Client ID: " CLIENT_ID
   read -p "Enter your Falcon API Key Client Secret: " CLIENT_SECRET
   echo
   echo "For the next variable (Falcon CID), use the entire string include the 2-character hash which you can find at https://falcon.crowdstrike.com/hosts/sensor-downloads"
   read -p "Enter your Falcon CID: " CS_CID
   echo
   read -p "Enter your Falcon Cloud [us-1]: " CS_CLOUD
   CS_CLOUD=${CS_CLOUD:=us-1}
   echo                                                                                                                                                                                         

cat <<EOF > tmpsecret.json
{
  "FalconClientId":"$CLIENT_ID", 
  "FalconSecret":"$CLIENT_SECRET",
  "FalconCID":"$CS_CID" ,
  "CSCloud":"$CS_CLOUD" 
}
EOF

tmpFalconSecret=$(aws secretsmanager list-secrets --query 'SecretList[?Name==`crowdstrike-falcon-api`].Name' --output text)
if [[ "$tmpFalconSecret" == 'crowdstrike-falcon-api' ]] 
then
  aws secretsmanager put-secret-value --secret-id crowdstrike-falcon-api --secret-string file://tmpsecret.json
  FalconSecretArn=$(aws secretsmanager list-secrets --query 'SecretList[?Name==`crowdstrike-falcon-api`].ARN' --output text)
  aws ssm put-parameter --name=psFalconSecretArn --value="${FalconSecretArn}" --region=$AWS_REGION --type=String --overwrite
else
  FalconSecretArn=$(aws secretsmanager create-secret --name crowdstrike-falcon-api --query 'ARN' --output text) 
  aws secretsmanager put-secret-value --secret-id crowdstrike-falcon-api --secret-string file://tmpsecret.json 
  aws ssm put-parameter --name=psFalconSecretArn --value="${FalconSecretArn}" --region=$AWS_REGION --type=String --overwrite 
fi

rm tmpsecret.json

echo "AWS Secrets Manager secret $tmpFalconSecret updated."

echo "Re-run failed build jobs from CodePipeline. Select the pipeline and click 'Release Change' to trigger the job".
echo
echo "The 'sensor-import-pipeline' triggers the 'sensor-image-import' and 'falcon-eks-deploy' build jobs."
echo "The 'webapp-deploy-pipeline' triggers the 'webapp-image-build' and 'webapp-eks-deploy' build jobs."
echo
