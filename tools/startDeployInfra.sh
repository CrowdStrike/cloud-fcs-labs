NC="\033[0;0m"

#git clone https://github.com/CrowdStrike/devdays.git  #NOT APPLICABLE, here for reference.

env_up(){

EnvHash=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 5)
S3Bucket="fcslab-${EnvHash}"
#EnvHash=$(aws ssm get-parameter --name=EnvHash --query 'Parameter.Value' --output text)
#S3Bucket=$(aws ssm get-parameter --name=S3Bucket --query 'Parameter.Value' --output text)
AWS_REGION='us-east-1'
S3Prefix='deployInfra'
#StackName=$(aws ssm get-parameter --name=InfraStack --query 'Parameter.Value' --output text)
StackName="fcslab-stack-${EnvHash}"
TemplateName='deployInfra.yaml'

   echo 
   echo "Welcome to the Falcon Cloud Security Workshop - AWS Infrastructure deployment stacks$NC"
   echo 
   echo "Creating S3 bucket..."
   aws s3api create-bucket --bucket $S3Bucket --region $AWS_REGION
   echo
   echo "Copying FCS-lab files to $S3Bucket"   
   aws s3 cp ../ s3://${S3Bucket}/ --recursive 
   echo
   echo "Building AWS lab environment...$NC"

   aws cloudformation create-stack --stack-name $StackName --template-url https://${S3Bucket}.s3.amazonaws.com/${S3Prefix}/${TemplateName} --region $AWS_REGION --disable-rollback \
   --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
   --parameters \
   ParameterKey=S3Bucket,ParameterValue=S3Bucket \
   ParameterKey=S3Prefix,ParameterValue=${S3Prefix} \
   ParameterKey=EnvHash,ParameterValue=EnvHash

    echo "The Cloudformation stack will take 20-30 minutes to complete.$NC"
    echo "\n\nCheck the status at any time with the command \n\naws cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION$NC\n\n"

}
env_up