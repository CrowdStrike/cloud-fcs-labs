#------------------------#                      
#  deployFalcon cleanup  #
#------------------------#                    

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

## Delete Falcon protection components to reset the cluster for re-running deployFalcon.
# note: deleting the falcon-operator (below) hangs. You can just leave it if you prefer.
# kubectl delete daemonset falcon-node-sensor -n falcon-system
# kubectl delete -f https://github.com/CrowdStrike/falcon-operator/releases/latest/download/falcon-operator.yaml

# StackSet instance deletion
accountId=$(aws sts get-caller-identity --query Account --output text)
aws cloudformation delete-stack-instances --stack-set-name CrowdStrike-Horizon-EB-Stackset --regions us-east-1 --no-retain-stacks --accounts ${accountId}

# S3 bucket empyting and deletion. 
codepipelineartifact=$(aws s3api list-buckets --query 'Buckets[*].[Name]' --output text | grep codepipelineartifact)
if [[ $codepipelineartifact ]]
then
read -n 4 -p  "Do you want to empty the contents of S3 bucket: $codepipelineartifact [yes]: " DeleteCPA
DeleteCPA=${DeleteCPA:=yes}
if [[ $DeleteCPA = "yes" ]]
then
aws s3 rm --recursive s3://$codepipelineartifact
echo "Bucket $codepipelineartifact emptied!"
else
echo "Did not empty $codepipelineartifact"
fi
fi

trailbucket=$(aws s3api list-buckets --query 'Buckets[*].[Name]' --output text | grep trailbucket)
if [[ $trailbucket ]]
then
read -n 4 -p  "Do you want to delete S3 bucket: $trailbucket [yes]: " DeleteTB
DeleteTB=${DeleteTB:=yes}
if [[ $DeleteTB = "yes" ]]
then
aws s3 rm --recursive s3://$trailbucket
aws s3 rb s3://$trailbucket --force
echo "Bucket $trailbucket deleted!"
else
echo "Did not delete $trailbucket"
fi
fi



sleep 60

# Delete deployFalcon CloudFormation stacks
tmpStackNameFalcon=$(aws cloudformation describe-stacks --query 'Stacks[*].[StackName]' --output text | grep fcs-falcon-stack)
tmpEnvHashFalcon="${tmpStackNameFalcon:0:22}"                                                                                                                                                                                                                   
echo $tmpEnvHashFalcon
aws cloudformation delete-stack --stack-name $tmpEnvHashFalcon

#-----------------------#                       
#  deployInfra cleanup  #
#-----------------------# 

## If you run this section separately (after running deployFalcon stack deletion) Run from AWS CloudShell

# S3 bucket empyting and deletion. 
loggingbucket=$(aws s3api list-buckets --query 'Buckets[*].[Name]' --output text | grep confidentiallogging)
if [[ $loggingbucket ]]
then
read -n 4 -p  "Do you want to empty the contents of S3 bucket: $loggingbucket [yes]: " DeleteLB
DeleteLB=${DeleteLB:=yes}
if [[ $DeleteLB = "yes" ]]
then
aws s3 rm --recursive s3://$loggingbucket
echo "Bucket $loggingbucket emptied!"
else
echo "Did not empty $loggingbucket"
fi
fi

# Delete deployInfra CloudFormation stacks
tmpStackNameInfra=$(aws cloudformation describe-stacks --query 'Stacks[*].[StackName]' --output text | grep fcs-infra-stack)
tmpEnvHashInfra="${tmpStackNameInfra:0:21}"                                                                                                                                                                                                                                                                                                                                                                                                                                      
echo $tmpEnvHashInfra
aws cloudformation delete-stack --stack-name $tmpEnvHashInfra

# Delete eksctl stacks 
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-cluster-addon-iamserviceaccount-kube-system-aws-load-balancer-controller
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-cluster-addon-iamserviceaccount-default-pod-s3-access
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-cluster-nodegroup-nodegroup
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-cluster-addon-iamserviceaccount-kube-system-aws-node
sleep 300
aws cloudformation delete-stack --stack-name eksctl-fcs-lab-EKS-cluster-cluster