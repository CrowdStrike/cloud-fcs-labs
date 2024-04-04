#----------------------#
#  Secret Repair tool  #
#----------------------#

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

echo "To update Environment Variables in affected CodeBuild jobs, cleanup cluster resources, and re-run the pipelines,"
echo "uncomment code blocks below as indicated."
echo
echo

#------------------------------------------------------#
# CodeBuild variable repair, EKS cleanup, and redeploy #
#------------------------------------------------------#

# Sample code in this block reserved for future use - leave commented out
#   FalconClientId=$(aws secretsmanager get-secret-value --secret-id crowdstrike-falcon-api --query 'SecretString' --output text | jq -r '.FalconClientId')
#   FalconSecret=$(aws secretsmanager get-secret-value --secret-id crowdstrike-falcon-api --query 'SecretString' --output text | jq -r '.FalconSecret')
#   FalconCID=$(aws secretsmanager get-secret-value --secret-id crowdstrike-falcon-api --query 'SecretString' --output text | jq -r '.FalconCID')
#   CSCloud=$(aws secretsmanager get-secret-value --secret-id crowdstrike-falcon-api --query 'SecretString' --output text | jq -r '.CSCloud')


# Set ECR RepoURI variable 
RepoECR=$(aws ecr describe-repositories --query 'repositories[0].[repositoryUri]' --output text | cut -d "/" -f 1)

# Uncomment to reset CodeBuild Environment Variables - Create json configs for updating build jobs
# cat <<EOF > update-webapp-image-build.json
# {
#     "name": "webapp-image-build",
#     "environment": {
#         "type": "LINUX_CONTAINER",
#         "image": "aws/codebuild/standard:5.0",
#         "computeType": "BUILD_GENERAL1_SMALL",
#         "environmentVariables": [
#             {
#                 "name": "FALCON_CLIENT_ID",
#                 "value": "${FalconSecretArn}:FalconClientId",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "FALCON_CLIENT_SECRET",
#                 "value": "${FalconSecretArn}:FalconSecret",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "CS_CLOUD",
#                 "value": "${FalconSecretArn}:CSCloud",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "REPO_ECR",
#                 "value": "${RepoECR}/webapp",
#                 "type": "PLAINTEXT"
#             },
#             {
#                 "name": "CS_SCAN_IMAGE",
#                 "value": "False",
#                 "type": "PLAINTEXT"
#             }
#         ]
#     }
# }
# EOF
# cat <<EOF > update-sensor-image-import.json
# {
#     "name": "sensor-image-import",
#     "environment": {
#         "type": "LINUX_CONTAINER",
#         "image": "aws/codebuild/standard:5.0",
#         "computeType": "BUILD_GENERAL1_SMALL",
#         "environmentVariables": [
#             {
#                 "name": "FALCON_CLIENT_ID",
#                 "value": "${FalconSecretArn}:FalconClientId",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "FALCON_CLIENT_SECRET",
#                 "value": "${FalconSecretArn}:FalconSecret",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "FALCON_CID",
#                 "value": "${FalconSecretArn}:FalconCID",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "CS_CLOUD",
#                 "value": "${FalconSecretArn}:CSCloud",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "REPO_URI",
#                 "value": "${RepoECR}",
#                 "type": "PLAINTEXT"
#             },
#             {
#                 "name": "AWS_REGION",
#                 "value": "us-east-1",
#                 "type": "PLAINTEXT"
#             },
#             {
#                 "name": "CS_SCAN_IMAGE",
#                 "value": "True",
#                 "type": "PLAINTEXT"
#             }
#         ]
#     }
# }
# EOF
# cat <<EOF > update-falcon-eks-deploy.json
# {
#     "name": "falcon-eks-deploy",
#     "environment": {
#         "type": "LINUX_CONTAINER",
#         "image": "aws/codebuild/standard:5.0",
#         "computeType": "BUILD_GENERAL1_SMALL",
#         "environmentVariables": [
#             {
#                 "name": "FALCON_CLIENT_ID",
#                 "value": "${FalconSecretArn}:FalconClientId",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "FALCON_CLIENT_SECRET",
#                 "value": "${FalconSecretArn}:FalconSecret",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "FALCON_CID",
#                 "value": "${FalconSecretArn}:FalconCID",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "CS_CLOUD",
#                 "value": "${FalconSecretArn}:CSCloud",
#                 "type": "SECRETS_MANAGER"
#             },
#             {
#                 "name": "REPO_URI",
#                 "value": "${RepoECR}",
#                 "type": "PLAINTEXT"
#             },
#             {
#                 "name": "AWS_REGION",
#                 "value": "us-east-1",
#                 "type": "PLAINTEXT"
#             },
#             {
#                 "name": "KAC_IMAGE_REPO",
#                 "value": "${RepoECR}/falcon-kac",
#                 "type": "PLAINTEXT" 
#             },
#             {
#                 "name": "EKS_CLUSTER_NAME",
#                 "value": "fcs-lab",
#                 "type": "PLAINTEXT"
#             },
#             {
#                 "name": "CS_SCAN_IMAGE",
#                 "value": "True",
#                 "type": "PLAINTEXT"
#             }
#         ]
#     }
# }
# EOF

# Uncomment to apply new environment variables to existing CodeBuild projects
# aws codebuild update-project --cli-input-json file://update-sensor-image-import.json --no-paginate --no-cli-pager
# aws codebuild update-project --cli-input-json file://update-webapp-image-build.json --no-paginate --no-cli-pager
# aws codebuild update-project --cli-input-json file://update-falcon-eks-deploy.json --no-paginate --no-cli-pager

# Uncomment to trigger CodePipeline pipeline jobs
# aws codepipeline start-pipeline-execution --name sensor-import-pipeline
# aws codepipeline start-pipeline-execution --name webapp-deploy-pipeline

# Informational - no need to uncomment
# echo "The 'sensor-import-pipeline' triggers the 'sensor-image-import' and 'falcon-eks-deploy' build jobs."
# echo "The 'webapp-deploy-pipeline' triggers the 'webapp-image-build' and 'webapp-eks-deploy' build jobs."

# Uncomment this block to cleanup CodeBuild envvar config scripts
# rm update-sensor-image-import.json 
# rm update-webapp-image-build.json 
# rm update-falcon-eks-deploy.json