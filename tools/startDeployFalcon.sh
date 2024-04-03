#-----------------------------------#
#  Start FCS FalconStack deployment  #
#-----------------------------------#

# The startDeployFalcon is the final step of FCS-Lab deployment which includes creation of CI/CD pipelines for ECR/EKS protection components

# Prerequisite for running the startDeployFalcon script requires the you already provisioned the FCSlab InfraStack and that Parameter Store has entries for:
  # psEnvHash, psS3Bucket, psInfraStack, and psLoggingBucket.
  # If any of these parameters are missing, delete any FCS-Lab stacks in CloudFormation (including EKS clusters with "fcs-lab"), and start from the beginning (startDeployInfra.sh)
  # you could also populate the parameters manually with the ./ParameterSetup.sh or ./setStackParameters.yaml

# startDeployFalcon creates a reusable secret called "crowdstrike-falcon-api" in AWS Secrets Manager. 
  # If that secret already exists, you can skip this script, start with deployFalcon.yaml and leave the "Falcon API Credentials" fields blank.
  # You can also create the secret separately using ./storeSecrets.yaml template

# Check shell outputs and CloudFormation stack status to confirm that all commands complete successfully.

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

tmpFalconSecret=$(aws secretsmanager list-secrets --query 'SecretList[?Name==`crowdstrike-falcon-api`].Name' --output text)
if [[ "$tmpFalconSecret" == 'crowdstrike-falcon-api' ]] 
then
  aws secretsmanager put-secret-value --secret-id crowdstrike-falcon-api --secret-string file://tmpsecret.json
else
  FalconSecretArn=$(aws secretsmanager create-secret --name crowdstrike-falcon-api --query 'ARN' --output text) 
  aws secretsmanager put-secret-value --secret-id crowdstrike-falcon-api --secret-string file://tmpsecret.json 
  aws ssm put-parameter --name=psFalconSecretArn --value="${FalconSecretArn}" --region=$AWS_REGION --type=String --overwrite 
fi

rm tmpsecret.json

echo " "
response=$(aws cloudformation create-stack --stack-name $StackName --template-url https://${tmpS3Bucket}.s3.amazonaws.com/${S3Prefix}/${TemplateName} --region $AWS_REGION --disable-rollback \
--capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
--parameters \
ParameterKey=DeployCSPM,ParameterValue=$CSPMDeploy \
ParameterKey=DeployCSPMSampleDetections,ParameterValue=$IOAIOMDeploy)

# echo $response 
if [[ "$response" == *"StackId"* ]]
then
echo "The Cloudformation stack will take 20-30 minutes to complete"
echo 
echo "Check the status at any time with the command"
echo 
echo "aws cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION"
else
echo "Stack creation failed. Check CloudFormation logs for details, or try:"
echo 
echo "cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION}"
fi
 
}
env_up