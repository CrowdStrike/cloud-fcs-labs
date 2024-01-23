NC="\033[0;0m"

env_up(){
# EnvHash=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 5)
# S3Bucket=fcs-stack-${EnvHash}
AWS_REGION='us-east-1'
S3Prefix='deployFalcon'
TemplateName='deployFalcon.yaml'

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

   tmpEnvHash=$(aws ssm get-parameter --name EnvHash --query 'Parameter.Value' --output text)                                                                                                                                                                                                                 

   S3Bucket=fcs-stack-${tmpEnvHash}
   StackName=fcs-falcon-stack-${tmpEnvHash}
   echo
   echo "Deploying Falcon protection and demo resources to AWS lab environment...$NC"
   aws cloudformation create-stack --stack-name $StackName --template-url https://${S3Bucket}.s3.amazonaws.com/${S3Prefix}/${TemplateName} --region $AWS_REGION --disable-rollback \
   --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
   --parameters \
   ParameterKey=S3Bucket,ParameterValue=${S3Bucket} \
   ParameterKey=S3Prefix,ParameterValue=${S3Prefix} \
   ParameterKey=EnvHash,ParameterValue=$tmpEnvHash \
   ParameterKey=FalconClientID,ParameterValue=$CLIENT_ID \
   ParameterKey=FalconClientSecret,ParameterValue=$CLIENT_SECRET \
   ParameterKey=CrowdStrikeCloud,ParameterValue=$CS_CLOUD \
   ParameterKey=FalconCID,ParameterValue=$CS_CID \
   ParameterKey=DeployCSPM,ParameterValue=$CSPMDeploy \
   ParameterKey=DeployCSPMSampleDetections,ParameterValue=$IOAIOMDeploy

    echo "The Cloudformation stack will take 20-30 minutes to complete.$NC"
    echo "\n\nCheck the status at any time with the command \n\naws cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION$NC\n\n"
}
env_up