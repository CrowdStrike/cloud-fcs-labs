#------------------------#                      
#  deployFalcon cleanup  #
#------------------------#                    

# set environment variables
AWS_REGION='us-east-1'

EnvHash=$(aws ssm get-parameter --name="psEnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
S3Bucket=$(aws ssm get-parameter --name="psS3Bucket" --query 'Parameter.Value' --output text --region=$AWS_REGION)
InfraStack=$(aws ssm get-parameter --name"psInfraStack-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
FalconStack=$(aws ssm get-parameter --name"psFalconStack-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
LoggingBucket=$(aws ssm get-parameter --name"psLoggingBucket-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
CodePipelineBucket=$(aws ssm get-parameter --name"psCodePipelineBucket-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
TrailBucket=$(aws ssm get-parameter --name"psTrailBucket-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)

## Run from the Bastion Host! 
## You can run the entire script at once if you want to delete all FCS-lab stacks, or you can run deployFalcon section separately.

# Delete ECR repositories to prevent a CloudFormation delete-stack race condition error
aws ecr delete-repository --repository-name falcon-kac --force
aws ecr delete-repository --repository-name falcon-sensor --force

# Delete k8s ingress and AWS load balancer controller to simplify stack cleanup
kubectl delete ingress webapp-ingress
helm uninstall aws-load-balancer-controller -n kube-system
helm repo remove eks
helm uninstall falcon-kac -n falcon-kac
# Replace with deletion of ELBv and Target groups
# aws elbv2 delete-target-group --target-group-arn targetgroup-arn
# aws elbv2 delete-load-balancer --load-balancer-arn loadbalancer-arn


## Delete Falcon protection components to reset the cluster for re-running deployFalcon.
# note: deleting the falcon-operator (below) hangs. You can just leave it if you prefer.
# kubectl delete daemonset falcon-node-sensor -n falcon-system
# kubectl delete -f https://github.com/CrowdStrike/falcon-operator/releases/latest/download/falcon-operator.yaml

# StackSet instance deletion
accountId=$(aws sts get-caller-identity --query Account --output text)
aws cloudformation delete-stack-instances --stack-set-name CrowdStrike-Horizon-EB-Stackset --regions us-east-1 --no-retain-stacks --accounts ${accountId}

# S3 bucket empyting and deletion. 
aws s3 rm --recursive --quiet s3://$CodePipelineBucket
echo "Bucket $CodePipelineBucket emptied!"

aws s3 rm --recursive --quiet s3://$TrailBucket
aws s3 rb --force s3://$TrailBucket 
echo "Bucket $TrailBucket deleted!"

# Time for the CSPM StackSet instance to delete
sleep 60

# Delete deployFalcon CloudFormation stacks
aws cloudformation delete-stack --stack-name $FalconStack

#-----------------------#                       
#  deployInfra cleanup  #
#-----------------------# 

## If you run this section separately (after running deployFalcon stack deletion) Run from AWS CloudShell

# Delete eksctl stacks 
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-addon-iamserviceaccount-kube-system-aws-load-balancer-controller
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-addon-iamserviceaccount-default-pod-s3-access
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-nodegroup-nodegroup
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-addon-iamserviceaccount-kube-system-aws-node

# S3 bucket empyting and deletion. 
aws s3 rm --recursive --quiet s3://$LoggingBucket
echo "Bucket $LoggingBucket emptied!"

# After cluster nodegroup stack deletes, delete the cluster
sleep 450
aws cloudformation delete-stack --stack-name "eksctl-fcs-lab-EKS-cluster"

# Delete deployInfra CloudFormation stacks based on stackname stored parameter
aws cloudformation delete-stack --stack-name $InfraStack