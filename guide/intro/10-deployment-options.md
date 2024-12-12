# Deployment Options

Cloud architecture natively supports resiliency, scale, and agility by leveraging Infrastructure-as-Code (IaC) and GitOps as primary mechanisms for deploying applications and resources. Compared to manual or ad-hoc procedures, IaC is less error-prone, may be triggered in response to events in the environment, and can deploy and build more quickly. While it can take a bit longer to learn to use IaC tools and to convert manual runbooks to actual code, IaC templates can then be used to trigger builds repeatedly in a fraction of the time. Also, improvements are incorporated into the templates which can be used to update existing deployments, and to assure that all future deployments follow a standard configuration.

Falcon Cloud Security encompasses several components which require separate deployment strategies, nearly all of which can be accomplished using Infrastructure-as-Code. The IaC templates used to build the CrowdStrike Falcon Cloud Security labs on AWS Workshop Studio are primarily written in CloudFormation with additional Bash, Python, and Kubernetes YAML manifests, all of which are provided to the environment through CloudFormation.

> [!NOTE]
> Go to the next page (“Lab Environment”) to continue discussion of the deployment mechanism used for this lab environment.

Components of Falcon Cloud Security, as well as other Falcon modules, can also be deployed using Terraform and Ansible. Code samples and documentation is available on CrowdStrike’s public GitHub site (https://github.com/CrowdStrike ), with most of the AWS-specific integrations at https://github.com/CrowdStrike/Cloud-AWS .

For AWS customers operating multi-account, multi-region environments, AWS typically recommends a landing zone solution such as AWS Organizations or AWS Control Tower. These services enable centralized management and guardrails to enforce security and operational configuration standards for new and existing AWS services. CrowdStrike is a member of the AWS Built-in competency program, working alongside AWS cloud and security foundations teams to develop and maintain an IaC mechanism for deploying all of the key components of Falcon Cloud Security, in tandem with AWS service dependencies. CrowdStrike’s AWS Built-in template deploys agentless Falcon Cloud Security Posture Management (CSPM), and sensor-based Cloud Workload Protection (CWP) on EC2, EKS, and Fargate. With ABI, deploy to the root of the multi-account landing zone, and Falcon CSPM and CWP are deployed to new accounts, regions, and resources automatically. Additional components will be supported by ABI in the future.

ABI encompasses three separate AWS deployment integrations:

- **Cloud Security Posture Management (CSPM)**

  - CSPM deployment creates and uses cross-account AWS IAM roles which enable the Falcon Platform to scan customer-deployed AWS services for indicators of misconfiguration which could introduce unnecessary risk.
  - CSPM deploys or uses an existing org-wide CloudTrail to capture AWS control plane API events.
  - CSPM creates AWS EventBridge rules which forward those CloudTrail events to the Falcon Platform to scan for evidence of suspicious activity which could indicate an attack in progress.
  - CSPM creates an AWS Lambda function in each new customer account for registration with the Falcon Platform.

- **Cloud Workload Protection (CWP) for EC2**

  - CWP for EC2 uses AWS Systems Manager Distributor to deploy the Falcon sensor on all new EC2 managed instances.
    > [!NOTE]
    > There are many supported methods for deploying the Falcon sensor. The use of the SSM Distributor Package is provided as a convenience for customers and works well as part of a CloudFormation stack.
  - This method can also be used to protect ECS clusters in EC2 mode.

- **Cloud Workload Protection (CWP) for EKS**

  - Falcon Cloud Security offer multiple layers of protection for Kubernetes clusters, all of which can be deployed as part of AWS Built-in
  - EC2 worker nodes are protected using the Falcon Operator which configures a Kubernetes daemonset, deploying a sensor pod for each EC2 instance.
  - Fargate nodes are protected by injecting a Falcon container sensor on launch.
  - The Falcon Kubernetes Admission Controller performs resource discovery and provides a policy engine for alerting or blocking deployment of vulnerable or misconfigured container images.

The CrowdStrike AWS Built-in (ABI) template and documentation is hosted by AWS at https://aws-abi.s3.amazonaws.com/guide/cfn-abi-crowdstrike-fcs/index.html with project source code published to the AWS public GitHub repository at https://github.com/aws-ia/cfn-abi-crowdstrike-fcs .
