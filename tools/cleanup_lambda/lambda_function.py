import json
import logging
import boto3
import requests
from botocore.exceptions import ClientError
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# CONSTANTS
SUCCESS = "SUCCESS"


class StackDeleteException(Exception):
    pass


def cfnresponse_send(event, responseStatus, responseData, physicalResourceId=None, noEcho=False):
    responseUrl = event["ResponseURL"]
    print(responseUrl)
    responseBody = {}
    responseBody["Status"] = responseStatus
    responseBody["Reason"] = "See the details in CloudWatch Log Stream: "
    responseBody["PhysicalResourceId"] = physicalResourceId
    responseBody["StackId"] = event["StackId"]
    responseBody["RequestId"] = event["RequestId"]
    responseBody["LogicalResourceId"] = event["LogicalResourceId"]
    responseBody["Data"] = responseData
    json_responseBody = json.dumps(responseBody)
    print("Response body:\n" + json_responseBody)
    headers = {"content-type": "", "content-length": str(len(json_responseBody))}
    try:
        response = requests.put(responseUrl, data=json_responseBody, headers=headers)
        print("Status code: " + response.reason)
    except Exception as e:
        print("send(..) failed executing requests.put(..): " + str(e))


def delete_stack(stack_name):
    cf_client = boto3.client("cloudformation", "us-east-1")

    def get_stack_status(stack_name):
        try:
            response = cf_client.describe_stacks(StackName=stack_name)
            stack_status = response["Stacks"][0]["StackStatus"]
        except Exception as e:
            if "does not exist" in str(e):
                return "DELETE_COMPLETE"

        logger.info(f"{stack_name} status is {stack_status}")

        return stack_status

    def stack_exists(stack_name):
        try:
            response = cf_client.describe_stacks(StackName=stack_name)
        except Exception as e:
            if "does not exist" in str(e):
                return False
            else:
                raise (e)

        if len(response["Stacks"]) > 0 and response["Stacks"][0]["StackStatus"] not in ["DELETE_COMPLETE"]:
            logger.info(f"stack {stack_name} exists")

            return True

        else:
            return False

    if stack_exists(stack_name):
        cf_client.delete_stack(StackName=stack_name)

        # check stack delete status
        stack_status = get_stack_status(stack_name)

        while stack_status != "DELETE_COMPLETE":
            time.sleep(10)
            stack_status = get_stack_status(stack_name)

            # Do we want to fail the entire delete process on failure?
            # What other stack statuses do we want to fail on?
            if stack_status in ["DELETE_FAILED"]:
                raise StackDeleteException(f"{stack_name} stack failed to delete")

        logger.info(f"stack {stack_name} has been deleted.")

    else:
        logger.warning(f"stack '{stack_name}' doesn't exist, or has already been deleted")


def delete_parameters():
    logger.info("deleting parameters")

    client = boto3.client("ssm")
    # delete psEnvHash parameter
    try:
        client.delete_parameter(Name="psEnvHash")
    except Exception as e:
        if "ParameterNotFound" in str(e):
            logger.warning("Parameter does not exist or has already been deleted.")
        else:
            raise (e)

    # delete psS3Bucket parameter
    try:
        client.delete_parameter(Name="psS3Bucket")
    except Exception as e:
        if "ParameterNotFound" in str(e):
            logger.warning("Parameter does not exist or has already been deleted.")
        else:
            raise (e)


def nuke_bucket(s3_client, bucket_name):
    s3_resource = boto3.resource("s3")

    # empty bucket
    logger.info(f"Emptying bucket {bucket_name}.")
    try:
        bucket = s3_resource.Bucket(bucket_name)
        bucket.objects.all().delete()

        # delete bucket
        s3_client.delete_bucket(Bucket=bucket_name)
        logger.info(f"{bucket_name} deleted.")
    except Exception as e:
        if "does not exist" in str(e):
            logger.warning(f"Bucket {bucket_name} does not exist, or has already been deleted.")
        else:
            raise (e)


def delete_load_balancer_resources():

    logger.info("searching for and deleting load balancers")

    client = boto3.client("elbv2")

    def get_associated_target_groups(load_balancer_arn):
        target_group_arns = []
        # Find associated target group arns
        response = client.describe_target_groups(LoadBalancerArn=load_balancer_arn)
        for tg in response["TargetGroups"]:
            logger.info(f"Found target group: {tg['TargetGroupName']}")
            target_group_arns.append(tg["TargetGroupArn"])
        return target_group_arns

    def get_associated_listeners(load_balancer_arn):
        # Find associated listeners
        listener_arns = []
        response = client.describe_listeners(LoadBalancerArn=load_balancer_arn)

        for listener in response["Listeners"]:
            listener_arns.append(listener["ListenerArn"])
            logger.info(f"Found listener: {listener['ListenerArn']}.")

        return listener_arns

    def load_balancer_has_fcs_tag(arn):
        response = client.describe_tags(ResourceArns=[arn])

        for tag in response["TagDescriptions"][0]["Tags"]:
            logger.debug(tag)
            if tag["Key"] == "elbv2.k8s.aws/cluster" and tag["Value"] == "fcs-lab":
                logger.info(f"Found fcs-lab load balancer")
                return True
        return False

    # fetch all load balancers

    load_balancers_arns = []

    load_balancers = client.describe_load_balancers()

    load_balancers_arns.extend([x["LoadBalancerArn"] for x in load_balancers["LoadBalancers"]])

    # iterate over markers
    while load_balancers.get("NextMarker"):
        load_balancers = client.describe_load_balancers(Marker=load_balancers.get("NextMarker"))
        load_balancers_arns.extend([x["LoadBalancerArn"] for x in load_balancers])

    logger.info(f"Load balancers found: {len(load_balancers_arns)}")

    # check if load balancer has fcs tag
    for arn in load_balancers_arns:
        if load_balancer_has_fcs_tag(arn):
            # Need to find all arns first before deleting
            listener_arns = get_associated_listeners(arn)
            target_group_arns = get_associated_target_groups(arn)

            for listener_arn in listener_arns:
                logger.info(f"Deleting listener: {listener_arn}")
                client.delete_listener(ListenerArn=listener_arn)

            for target_group_arn in target_group_arns:
                logger.info(f"Deleting target group: {target_group_arn}")
                client.delete_target_group(TargetGroupArn=target_group_arn)

            logger.info(f"Deleting load balancer: {arn}")
            client.delete_load_balancer(LoadBalancerArn=arn)


def delete_security_groups():
    client = boto3.client("ec2")

    logger.info("searching for and deleting security groups")

    def has_fcs_tag(tags):
        for tag in tags:
            if tag["Key"] == "elbv2.k8s.aws/cluster" and tag["Value"] == "fcs-lab":
                return True
        return False

    security_groups = []

    response = client.describe_security_groups()

    for sg in response["SecurityGroups"]:
        if sg.get("Tags"):
            security_groups.append({"security_group_id": sg["GroupId"], "tags": sg["Tags"]})

    while response.get("NextToken"):
        response = client.describe_security_groups()
        for sg in response["SecurityGroups"]:
            if sg.get("Tags"):
                security_groups.append({"security_group_id": sg["GroupId"], "tags": sg["Tags"]})

    for sg in security_groups:
        if has_fcs_tag(sg["tags"]):
            logger.info(f"{sg['security_group_id']} has fcs-lab tag")
            client.delete_security_group(GroupId=sg["security_group_id"])
            logger.info(f"{sg['security_group_id']} has been deleted")


def delete_ecr(ecr_name):
    client = boto3.client("ecr")

    logger.info(f"Deleting ECR repo: {ecr_name}")
    try:
        client.delete_repository(repositoryName=ecr_name)
    except Exception as e:
        if "RepositoryNotFoundException" in str(e):
            logger.warning(f"Repository {ecr_name} doesn't exist or has already been deleted.")


def lambda_handler(event, context):
    logger.info("Got event {}".format(event))
    logger.info("Context {}".format(context))

    if event["RequestType"] in ["Delete"]:

        # Set AWS region and get parameters
        region = "us-east-1"
        ssm = boto3.client("ssm", region_name=region)

        EnvHash = ssm.get_parameter(Name="psEnvHash", WithDecryption=False)["Parameter"]["Value"]
        S3Bucket = ssm.get_parameter(Name="psS3Bucket", WithDecryption=False)["Parameter"]["Value"]
        FalconStack = ssm.get_parameter(Name="psFalconStack-" + EnvHash, WithDecryption=False)["Parameter"]["Value"]
        CodePipelineBucket = ssm.get_parameter(Name="psCodePipelineBucket-" + EnvHash, WithDecryption=False)[
            "Parameter"
        ]["Value"]
        TrailBucket = ssm.get_parameter(Name="psTrailBucket-" + EnvHash, WithDecryption=False)["Parameter"]["Value"]
        VpcId = ssm.get_parameter(Name="psVpcId-" + EnvHash, WithDecryption=False)["Parameter"]["Value"]

        # Delete EKS stacks
        delete_stack("eksctl-fcs-lab-nodegroup-ng-1")
        delete_stack("eksctl-fcs-lab-addon-vpc-cni")
        delete_stack("eksctl-fcs-lab-addon-iamserviceaccount-kube-system-aws-load-balancer-controller")
        delete_stack("eksctl-fcs-lab-addon-iamserviceaccount-default-pod-s3-access")
        delete_stack("eksctl-fcs-lab-cluster")

        # Delete ECR Repositories
        delete_ecr("falcon-kac")
        delete_ecr("falcon-sensor")
        delete_ecr("web-dvwa")
        delete_ecr("webapp")

        # Delete load balancer, target groups, and rule
        delete_load_balancer_resources()

        # Delete security groups
        sg_delete_attempts = 0
        sg_is_deleted = False

        # Try 3 times to delete security groups with a pause of 5 seconds
        while sg_is_deleted is False:
            try:
                delete_security_groups()
                sg_is_deleted = True
            except Exception as e:
                if "DependencyViolation" in str(e) and sg_is_deleted <= 3:
                    time.sleep(5)
                    sg_delete_attempts += 1
                else:
                    raise (e)

        # Nuke buckets
        s3_client = boto3.client("s3")

        # nuke fcs lab bucket
        nuke_bucket(s3_client, f"fcslab-templates-{EnvHash}")

        # find and nuke confidential logging bucket
        buckets = s3_client.list_buckets()["Buckets"]
        for bucket in buckets:
            if "confidentialloggingbucket" in bucket["Name"] and EnvHash in bucket["Name"]:
                nuke_bucket(s3_client, bucket_name=bucket["Name"])

        # delete falcon stack
        delete_stack(FalconStack)

        # delete parameters
        delete_parameters()

        # send success response
        response = {"Status": "Complete"}
        cfnresponse_send(event, "SUCCESS", response, "CustomResourcePhysicalID")

    else:
        response = {"Status": "Complete"}
        cfnresponse_send(event, "SUCCESS", response, "CustomResourcePhysicalID")
