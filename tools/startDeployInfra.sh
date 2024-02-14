NC="\033[0;0m"

# git clone https://github.com/CrowdStrike/cloud-fcs-labs.git  #NOT APPLICABLE, here for reference.
# cd cloud-fcs-labs/tools/

env_up(){

# Set AWS region. 
#   Note: deployment to other regions has not been tested and may produce unexpected results.
AWS_REGION='us-east-1'

# set variables. These are written to SSM Parameter Store to enable repeat builds directly from CloudFormation using deployInfra.yaml.
EnvHash=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 5)
S3Bucket="fcslab-templates-${EnvHash}"
StackName="fcslab-infrastack-${EnvHash}"

aws ssm put-parameter --name=psEnvHash --value="${EnvHash}" --region=$AWS_REGION --allowed-pattern "^[a-zA-Z0-9]{5}$" --type=String --overwrite
aws ssm put-parameter --name=psS3Bucket --value="${S3Bucket}" --region=$AWS_REGION --type=String --overwrite 

S3Prefix='deployInfra'
TemplateName='deployInfra.yaml'

   echo 
   echo "Welcome to the Falcon Cloud Security Workshop - AWS Infrastructure deployment stacks$NC"
   echo 
   echo "Creating S3 bucket..."
   aws s3api create-bucket --bucket $S3Bucket --region $AWS_REGION
   echo
   echo "Copying FCS-lab files to $S3Bucket"   
   aws s3 cp ../ s3://${S3Bucket}/ --recursive --exclude ".git/*" --exclude ".DS_Store" --exclude ".gitignore" 
   echo
   echo "Building AWS lab environment...$NC"

   aws cloudformation create-stack --stack-name $StackName --template-url https://${S3Bucket}.s3.amazonaws.com/${S3Prefix}/${TemplateName} --region $AWS_REGION --disable-rollback \
   --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND #\
#    --parameters \
#    ParameterKey=S3Bucket,ParameterValue=${S3Bucket} \
#    ParameterKey=S3Prefix,ParameterValue=${S3Prefix} \
#    ParameterKey=EnvHash,ParameterValue=${EnvHash} \
#    ParameterKey=SetParams,Parameteralue=${SetParams}

    echo "The Cloudformation stack will take 20-30 minutes to complete.$NC"
    echo "\n\nCheck the status at any time with the command \n\naws cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION$NC\n\n"

}
env_up