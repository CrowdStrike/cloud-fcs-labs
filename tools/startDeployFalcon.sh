NC="\033[0;0m"

env_up(){
# EnvHash=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 5)
# S3Bucket=fcs-stack-${EnvHash}
AWS_REGION='us-east-1'
S3Prefix='deployFalcon'
TemplateName='deployFalcon.yaml'
tmpEnvHash=$(aws ssm get-parameter --name psEnvHash --query 'Parameter.Value' --output text) 
tmpS3Bucket=$(aws ssm get-parameter --name psS3Bucket --query 'Parameter.Value' --output text)
StackName=fcslab-falconstack-${tmpEnvHash}

   echo 
   echo "Welcome to the Falcon Cloud Security Workshop - Falcon Sensor deployment and AWS account CSPM registration $NC"
   echo 
   echo "You will asked to provide a Falcon API Key Client ID and Secret." 
   echo "You can create one at https://falcon.crowdstrike.com/support/api-clients-and-keys"
   echo 
   echo "The Dev Days Workshop environment requires the following API Scope permissions:"
   echo " - AWS Accounts:R"
   echo " - CSPM registration:R/W"
   echo " - CSPM remediation:R/W"
   echo " - Customer IOA rules:R/W"
   echo " - Hosts:R"
   echo " - Falcon Container Image:R/W"
   echo " - Falcon Images Download:R"
   echo " - Sensor Download:R"
   echo " - Event streams:R"
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
   echo "AWS users building on Isengard (and others in very restrictive environments) should answer 'false' on the next two questions."
   read -p "Register your AWS Account with Falcon CSPM [true]: " CSPMDeploy
   CSPMDeploy=${CSPMDeploy:=true}
   read -p "Generate cloud IoA and IoM sample detections [true]: " IOAIOMDeploy
   IOAIOMDeploy=${IOAIOMDeploy:=true}                                                                                                                                                                                                       

cat <<EOF > tmpsecret.json
{
  "FalconClientId":"$CLIENT_ID", 
  "FalconSecret":"$CLIENT_SECRET",
  "FalconCID":"$CS_CID" ,
  "CSCloud":"$CS_CLOUD" 
}
EOF

tmpFalconSecret=$(aws secretsmanager list-secrets --query 'SecretList[].Name[]' --output text | grep crowdstrike-falcon-api)
if [[ "$tmpFalconSecret" == 'crowdstrike-falcon-api' ]] 
then
  aws secretsmanager put-secret-value --secret-id crowdstrike-falcon-api --secret-string file://tmpsecret.json
else
  aws secretsmanager create-secret --name crowdstrike-falcon-api
  aws secretsmanager put-secret-value --secret-id crowdstrike-falcon-api --secret-string file://tmpsecret.json 
fi

rm tmpsecret.json

   echo
   echo "Deploying Falcon protection and demo resources to AWS lab environment...$NC"
   response=$(aws cloudformation create-stack --stack-name $StackName --template-url https://${tmpS3Bucket}.s3.amazonaws.com/${S3Prefix}/${TemplateName} --region $AWS_REGION --disable-rollback \
   --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
   --parameters \
   ParameterKey=DeployCSPM,ParameterValue=$CSPMDeploy \
   ParameterKey=DeployCSPMSampleDetections,ParameterValue=$IOAIOMDeploy)

echo $NC$response

    echo "$NC The Cloudformation stack will take 20-30 minutes to complete."
    echo "\n\nCheck the status at any time with the command \n\naws cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION$NC\n\n"
}
env_up