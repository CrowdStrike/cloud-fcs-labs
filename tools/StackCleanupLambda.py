import boto3

def handler(event, context):

  # Set AWS region and get parameters
  region = 'us-east-1'
  ssm = boto3.client('ssm', region_name=region)

  EnvHash = ssm.get_parameter(Name="psEnvHash", WithDecryption=False)['Parameter']['Value']
  S3Bucket = ssm.get_parameter(Name="psS3Bucket", WithDecryption=False)['Parameter']['Value']
  FalconStack = ssm.get_parameter(Name="psFalconStack-" + EnvHash, WithDecryption=False)['Parameter']['Value']
  CodePipelineBucket = ssm.get_parameter(Name="psCodePipelineBucket-" + EnvHash, WithDecryption=False)['Parameter']['Value']
  TrailBucket = ssm.get_parameter(Name="psTrailBucket-" + EnvHash, WithDecryption=False)['Parameter']['Value']
  VpcId = ssm.get_parameter(Name="psVpcId-" + EnvHash, WithDecryption=False)['Parameter']['Value']

  # Delete ECR repositories
  ecr_client = boto3.client('ecr')
  ecr_client.delete_repository(repositoryName='falcon-kac', force=True)
  ecr_client.delete_repository(repositoryName='falcon-sensor', force=True)

  # Delete ELB and target groups 
  elbv2 = boto3.client('elbv2')
  load_balancer = elbv2.describe_load_balancers(Query='LoadBalancers[].LoadBalancerArn[] | grep k8s-default-webappin')['LoadBalancers'][0]['LoadBalancerArn']
  elbv2.delete_load_balancer(LoadBalancerArn=load_balancer)

  target_group = elbv2.describe_target_groups(Query='TargetGroups[].TargetGroupArn[] | grep k8s-default-webapp')['TargetGroups'][0]['TargetGroupArn']
  elbv2.delete_target_group(TargetGroupArn=target_group)

  # Delete security groups
  ec2 = boto3.client('ec2') 
  security_groups = ec2.describe_security_groups(Filters=[{'Name':'tag:elbv2.k8s.aws/cluster', 'Values':['fcs-lab']}])['SecurityGroups']
  for group in security_groups:
    ec2.delete_security_group(GroupId=group['GroupId'])

# Bash code for what I'm trying to do above. Notice that VpcId is missing, how would I incorporate that)?
#   arSecurityGroups=$(aws ec2 get-security-groups-for-vpc --vpc-id $VpcId --filter Name=tag:elbv2.k8s.aws/cluster,Values=fcs-lab --query 'SecurityGroupForVpcs[].GroupId' --output text)
#   for s in ${arSecurityGroups[@]}; do
#   aws ec2 delete-security-group --group-id $s
#   done

  # Delete S3 buckets
  s3 = boto3.client('s3')
  s3.delete_objects(Bucket=CodePipelineBucket, Delete={'Objects': []})
  s3.delete_objects(Bucket=TrailBucket, Delete={'Objects': []}) 

  # Delete CloudFormation stack
  cfn = boto3.client('cloudformation')
  cfn.delete_stack(StackName = FalconStack)

  return "Cleanup complete"
