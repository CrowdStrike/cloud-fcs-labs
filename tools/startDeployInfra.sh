#-----------------------------------#
#  Start FCS InfraStack deployment  #
#-----------------------------------#

# All new FCS Lab deployments should start here. 
# This will generate a consistent hash value for deployed stacks, copy templates to a new S3 bucket, write parameters, and start the build.
# Check shell outputs and CloudFormation stack status to confirm that all commands complete successfully.

# Easiest way to get the files onto your machine
# git clone https://github.com/CrowdStrike/cloud-fcs-labs.git  
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

# Constants that you can change if you need to, in which case you may need to modify nested stack parameters.
S3Prefix='deployInfra'
TemplateName='deployInfra.yaml'

# Create S3 bucket for FCS-lab templates and code for InfraStack, EKS cluster, and FalconStack
aws s3api create-bucket --bucket $S3Bucket --region $AWS_REGION
echo
echo "Copying FCS-lab files to $S3Bucket"   
aws s3 cp ../ s3://${S3Bucket}/ --recursive --exclude ".git/*" --exclude ".DS_Store" --exclude ".gitignore" 
aws s3api put-bucket-versioning --bucket $S3Bucket --versioning-configuration Status=Enabled
aws s3api put-bucket-notification-configuration --bucket $S3Bucket --notification-configuration='{ "EventBridgeConfiguration": {} }'

response=$(aws cloudformation create-stack --stack-name $StackName --template-url https://${S3Bucket}.s3.amazonaws.com/${S3Prefix}/${TemplateName} --region $AWS_REGION --disable-rollback \
--capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND) 

#echo $response 
if [[ "$response" == *"StackId"* ]]
then
echo
echo "The Cloudformation stack will take 20-30 minutes to complete."
echo 
echo "Check the status at any time with the command"
echo 
echo "aws cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION"
echo
else
echo
echo "Stack creation failed. Check CloudFormation logs for details, or try:"
echo 
echo "cloudformation describe-stacks --stack-name $StackName --region $AWS_REGION}"
echo
fi

}
env_up