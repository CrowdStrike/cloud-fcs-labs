# #!/bin/bash

# # Get stack name and EnvHash from local EC2 instance meta-data

# # instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
# # stackName=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instanceId" "Name=key,Values=aws:cloudformation:stack-name" --query 'Tags[*].Value' --output text)
# # EnvHash=${stackName:16:5}
# # S3Bucket=fcs-stack-${EnvHash}
# # echo $EnvHash
# # echo $S3Bucket

# # create EnvHash SSM parameter via CLI
EnvHash=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 5)
read -n 4 -p  "Do you want to make $EnvHash your EnvHash SSM Parameter? [yes]: " putEnvHash
putEnvHash=${putEnvHash:=yes}
if [[ $putEnvHash = "yes" ]]
then
aws ssm put-parameter --name=EnvHash --value=$EnvHash --overwrite
else
read -p "Provide a unique 5-character hash value: " tmpEnvHash
aws ssm put-parameter --name=EnvHash --value=$tmpEnvHash --overwrite
fi
# echo $EnvHash
EnvHash=$(aws ssm get-parameter --name=EnvHash --query 'Parameter.Value' --output text)
S3Bucket=$(aws ssm put-parameter --name=S3Bucket --value="fcs-stack-${EnvHash}" --type=String --overwrite)
InfraStack=$(aws ssm put-parameter --name=InfraStack --value="fcs-infra-stack-${EnvHash}" --type=String --overwrite)
FalconStack=$(aws ssm put-parameter --name=FalconStack --value="fcs-falcon-stack-${EnvHash}" --type=String --overwrite)

# # create falcon secrets
# secretName="FalconAPIKey"
read -p "Give your secret a name: " secretName
client_id=$(aws secretsmanager get-secret-value --secret-id FalconAPIKey --query 'SecretString' --output text | grep client_id) 
client_id="${client_id:16:5}***************************"
# echo $client_id 
read -p "Enter your Falcon API Key Client ID: [$client_id] " CLIENT_ID
read -p "Enter your Falcon API Key Client Secret: " CLIENT_SECRET
echo "For the next variable (Falcon CID), use the entire string include the 2-character hash which you can find at https://falcon.crowdstrike.com/hosts/sensor-downloads"
read -p "Enter your Falcon CID: " CS_CID
echo
read -p "Enter your Falcon Cloud [us-1]: " CS_CLOUD
CS_CLOUD=${CS_CLOUD:=us-1}

# secretString="{\"client_id\":\"${FalconClientID}\",\"client_secret\":\"${FalconClientSecret}\",\"cid\":\"${FalconCID}\",\"cs_cloud\":\"${CrowdStrikeCloud}\"}"
# echo $secretString
aws secretsmanager create-secret \
   --name $secretName \
   --secret-string "{\"client_id\":\"${CLIENT_ID}\",\"client_secret\":\"${CLIENT_SECRET}\",\"cid\":\"${CS_CID}\",\"cs_cloud\":\"${CS_CLOUD}\"}" 