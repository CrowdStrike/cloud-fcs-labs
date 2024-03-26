## Falcon Cloud Security Lab ##

### Overview: ###

Falcon Cloud Security (FCS) Lab provides CloudFormation templates that build a foundational AWS environment for testing FCS deployment mechanisms, and for launching a Metasploit-based attack against vulnerable systems. When both sets of stacks are deployed together, the builder has a representative example of Falcon Cloud Security components include agent-based runtime protection, agentless/API-driven IoA/IoM detection, and pre-runtime image scanning. The provisioning has been divided into two sets of nested stacks:

**1) deployInfra stack:**

This set of nested stacks builds the following resources:
* an EKS cluster with a managed nodegroups and IRSA roles for subsequent pod access roles
* a Linux Bastion host for managing the EKS environment 
* a Kali/Metasploit instance for demonstrating an attack on a container running a vulnerable package.
* Interactive access to hosts provided by SSM Session Manager Connect
* Security Groups only grant access between Kali and the vulnerable container (deployed in the next stack) to maintain a secure environment.
* S3 buckets for CloudFormation template files, and S3 demo environment
* Miscellaneous instance bootstrap files, IAM roles, and VPC resources.
* Lambdas for resource provisioning and cleanup.

***NOTE:*** the EksCodeBuild stack uses CodeBuild and eksctl to deploy the cluster, nodegroups, and IAMserviceaccounts. These deploy as separate stacks that must be deleted separately (or use the ./tools/StackCleanup.sh script).

***Note:*** There are no prerequisites for building the deployInfra stack beyond an AWS account and an IAM role with adequate permissions. AWS service costs will apply for running services.

**2) deployFalcon stack:**
This set of nested stacks deploys Falcon Cloud Security components and requires an active Falcon platform license. Before you start, you will need to create an API Client ID and Secret in the Falcon console with the following scopes. Some additional scopes have been added to support additional/optional components. Store your API Secret in a safe place. You will also need your Falcon CID with offset hash, and the Falcon cloud region (typically, us-1, us-2, or eu-1). For us-1, the URL for generating API keys is located at https://falcon.crowdstrike.com/support/api-clients-and-keys.

AWS Accounts:R"
CSPM registration:R/W"
CSPM remediation:R/W"
Custom IOA rules:R/W"
Hosts:R"
Falcon Container Image:R/W"
Falcon Images Download:R"
Sensor Download:R"
Event streams:R"

The following resources are provisioned by the deployFalcon stacks:
* CodeCommit repo with buildspecs, Dockerfiles, k8s manifests, and other Falcon image scanning scripts.
* CodePipeline and CodeBuild projects for pushing Falcon sensors to local ECR repositories and deploying to EKS
* CodePipeline/CodeBuild job to build and scan a 'vulnerable-image' This should fail.
* AWS WAF ACL rules later connected to an ALB deployed via EKS ingress and AWS Load Balancer Controller.
* AWS Load Balancer Controller via Helm deployed on EKS.
* Falcon Operator which governs deployment of the Falcon sensor daemonset
* Falcon Kubernetes Admission Controller via Helm install
* Falcon container images copied to customer-owned ECR repositories via Falcon image pull script. 
* Two S3 buckets to support Falcon Cloud Security Posture Management (Trail) and CodePipeline artifacts
* Lambda functions and StackSets to handle CSPM account registration across multiple regions.
* Sample generation of misconfigured resources to create IOMs in Falcon CSPM console.
* EventBridge rules and CloudTrail created to send telemetry stream to Falcon platform.
* Miscellaneous IAM roles

**Tools:**
Tools are provided to assist with tasks such as streamlined stack deployment, spot creation of parameters and secrets, and comprehension stack resource deletion. Refer to toolsManifest.txt for details 

### Getting Started ###

Start by logging into your AWS account with a role and policies to support deployment of all services mentioned above. Use the CloudFormation service and/or CloudShell to take action. Note: this process is intended to run in AWS region **us-east-1**.

1. Clone the GitHub repo (or unzip cloud-fcs-labs.zip) to a directory on your machine. Configure AWS CLI credentials sufficient to create an S3 bucket and build infrastructure through CloudFormation. You could also run everything from AWS CloudShell to avoid configuring AWS credentials locally.
````
git clone https://github.com/CrowdStrike/cloud-fcs-labs.git  
````
2. From a bash shell, change to the "tools" subdirectory of the unzipped archive. 
````
cd cloud-fcs-labs/tools
````
3. Run the following command to make the scripts executable.
````
chmod +x *.sh 
````
4. Launch the deployInfra stacks. No parameter inputs are required. Build time is about 20 min.
```
./startDeployInfra.sh
``` 
    a. A set of 7 nested stacks are deployed in addition to the parent 'fcslab-infrastack'.
    b. A set of 5 more standalone 'eksctl' stacks are launched from the EKSCodeBuild stack including EKS Cluster, EKS nodegroup, and 3 EKS IAMserviceaccount stacks. When deleting the FCS Workshop, these 5 stacks must be deleted separately. (This is handled seamlessly by using the ./tools/StackCleanup.sh script).
5. Get a cup of coffee, generate Falcon API keys, etc.
6. After all deployInfra stacks complete successfully, you can launch the deployFalcon stacks.
7. Starting from inside the 'tools' subdirectory directory, launch the deployFalcon stacks. Total build time is about 15 minutes, including the CodeBuild jobs which take some additional time after the CloudFormation stacks complete.
````
./startDeployFalcon.sh
````
    - Enter the following Falcon credential values when prompted:
        - Falcon CID
        - Falcon API Client ID
        - Falcon API Secret
        - Falcon Cloud
        - CSPM deployment
        - CSPM IOM/IOA samples deployment
    
    a. There will be 2-4 nested stacks under the main deployFalcon stack (depending on whether you deploy CSPM and samples).
    b. For CSPM deployments including IOA detection, there will be one StackSet instance, "CrowdStrike-Horizon-EB-Stackset".
8.  Your environment is complete. See the lab guide for running the demo.

9. **CLEAN UP**
    a. Use the StackCleanup.sh script in the "tools" subdirectory to avoid deletion errors in CloudFormation.
    b. Start the stack deletion script from Bastion Host as follows:
        - Use Session Manager Connect to login to the Linux Bastion
        - At the shell prompt, run these commands:
````   
tmpS3Bucket=$(aws ssm get-parameter --name psS3Bucket --region=us-east-1 --query 'Parameter.Value' --output text)
aws s3 cp s3://${tmpS3Bucket}/tools/StackCleanup.sh .
chmod +x StackCleanup.sh
./StackCleanup.sh
````
        



