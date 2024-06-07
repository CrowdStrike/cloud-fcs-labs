#--------------------------#                      
#  FCS Lab Cleanup Script  #
#--------------------------#  

#---------------#
#  K8s cleanup  # 
#---------------#

k8s_cleanup(){
## Delete Falcon protection components to reset the cluster for re-running deployFalcon.

echo "Deleting Kubernetes protection components on EKS..."

# Run this block to cleanup Falcon protection components prior to running the 'sensor-import-pipeline' CodePipeline job
kubectl delete falconnodesensors -A --all
kubectl delete falconcontainers --all
kubectl delete falconadmission --all
kubectl delete -f https://github.com/CrowdStrike/falcon-operator/releases/latest/download/falcon-operator.yaml
helm uninstall falcon-kac -n falcon-kac

# Run this block after removing falcon components, to refresh the cluster and prep for Infra stack cleanup
kubectl delete ingress webapp-ingress
helm uninstall aws-load-balancer-controller -n kube-system
helm repo remove eks
# kubectl delete sa aws-load-balancer-controller -n kube-system
kubectl delete deployment webapp

}

falconstack_cleanup(){

#------------------------#                      
#  deployFalcon cleanup  #
#------------------------#                    

echo "Removing Falcon Stack and related resources..."

# set environment variables
AWS_REGION='us-east-1'

EnvHash=$(aws ssm get-parameter --name "psEnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
S3Bucket=$(aws ssm get-parameter --name "psS3Bucket" --query 'Parameter.Value' --output text --region=$AWS_REGION)
FalconStack=$(aws ssm get-parameter --name "psFalconStack-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
CodePipelineBucket=$(aws ssm get-parameter --name "psCodePipelineBucket-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
TrailBucket=$(aws ssm get-parameter --name "psTrailBucket-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)

## Run from the Bastion Host! 
## You can run the entire script at once if you want to delete all FCS-lab stacks, or you can run deployFalcon section separately.

# Delete ECR repositories to prevent a CloudFormation delete-stack race condition error
aws ecr delete-repository --repository-name falcon-kac --force
aws ecr delete-repository --repository-name falcon-sensor --force

# Replace with deletion of ELBv and Target groups
loadBalancerArn=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerArn]' --output text | grep k8s-default-webappin)
aws elbv2 delete-load-balancer --load-balancer-arn $loadBalancerArn
sleep 30
targetGroupArn=$(aws elbv2 describe-target-groups --query 'TargetGroups[].[TargetGroupArn]' --output text | grep k8s-default-webapp)
aws elbv2 delete-target-group --target-group-arn $targetGroupArn

# StackSet instance deletion
accountId=$(aws sts get-caller-identity --query Account --output text)
aws cloudformation delete-stack-instances --stack-set-name CrowdStrike-Horizon-EB-Stackset --regions us-east-1 --no-retain-stacks --accounts ${accountId}

# S3 bucket empyting and deletion. 
aws s3 rm --recursive --quiet s3://$CodePipelineBucket
echo "Bucket $CodePipelineBucket emptied"

aws s3 rm --recursive --quiet s3://$TrailBucket
sleep 60
aws s3 rb --force s3://$TrailBucket 
echo "Bucket $TrailBucket deleted"

# Time for the CSPM StackSet instance to delete
# sleep 60

# Delete deployFalcon CloudFormation stacks
aws cloudformation delete-stack --stack-name $FalconStack

echo "Falcon Stack deleted"

}

infrastack_cleanup(){

#-----------------------#                       
#  deployInfra cleanup  #
#-----------------------# 

echo "Deleting InfraStack and related resources"

## If you run this section separately (after running deployFalcon stack deletion), you can run from AWS CloudShell 

# set environment variables
AWS_REGION='us-east-1'

EnvHash=$(aws ssm get-parameter --name "psEnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
S3Bucket=$(aws ssm get-parameter --name "psS3Bucket" --query 'Parameter.Value' --output text --region=$AWS_REGION)
LoggingBucket=$(aws ssm get-parameter --name "psLoggingBucket-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
InfraStack=$(aws ssm get-parameter --name "psInfraStack-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)
VpcId=$(aws ssm get-parameter --name "psVpcId-$EnvHash" --query 'Parameter.Value' --output text --region=$AWS_REGION)

# Delete eksctl stacks 
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-addon-iamserviceaccount-kube-system-aws-load-balancer-controller
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-addon-iamserviceaccount-default-pod-s3-access
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-addon-iamserviceaccount-kube-system-aws-node
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-nodegroup-ng-1

while [ "$(aws cloudformation describe-stacks --stack-name eksctl-fcs-lab-nodegroup-ng-1 --query 'Stacks[].StackStatus' --output text)" = "DELETE_IN_PROGRESS" ]; do 
  echo "Waiting for eksctl-fcs-lab-nodegroup-ng-1 stack to delete"   
  sleep 30
done

# S3 bucket empyting and deletion. 
aws s3 rm --recursive --quiet s3://$LoggingBucket
aws s3 rb --force s3://$LoggingBucket
echo "Bucket $LoggingBucket deleted"

# After cluster nodegroup stack deletes, delete the cluster
aws cloudformation delete-stack --stack-name "eksctl-fcs-lab-cluster"

while [ "$(aws cloudformation describe-stacks --stack-name eksctl-fcs-lab-cluster --query 'Stacks[].StackStatus' --output text)" = "DELETE_IN_PROGRESS" ]; do 
  echo "Waiting for eksctl-fcs-lab-cluster stack to delete"   
  sleep 30
done
arSecurityGroups=$(aws ec2 get-security-groups-for-vpc --vpc-id $VpcId --filter Name=tag:elbv2.k8s.aws/cluster,Values=fcs-lab --query 'SecurityGroupForVpcs[].GroupId' --output text)
for s in ${arSecurityGroups[@]}; do
  aws ec2 delete-security-group --group-id $s
done

# S3 bucket empyting and deletion. 
aws s3 rm --recursive --quiet s3://$S3Bucket
aws s3 rb --force s3://$S3Bucket
echo "Bucket $S3Bucket deleted"

# Delete deployInfra CloudFormation stacks based on stackname stored parameter
aws cloudformation delete-stack --stack-name $InfraStack

echo "Infra Stack deleted, exiting"

}

read -p "Are you deleting K8s protection only, FalconStack only, or FalconStack AND InfraStack resources? [k8s|falcon|all]: " CleanupPrompt
   CleanupPrompt=${CleanupPrompt:=falcon}
   if [ $CleanupPrompt = k8s ]; then
      k8s_cleanup
      exit 1
   elif [ $CleanupPrompt = falcon ]; then
      falconstack_cleanup
      exit 1

   elif [ $CleanupPrompt = all ]; then
      falconstack_cleanup
      infrastack_cleanup      
      exit 1 
   else
      echo "Not a valid response, exiting cleanup"
      exit 1
   fi
