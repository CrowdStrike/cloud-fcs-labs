# Lab Environment

The Falcon Cloud Security lab environment is designed to be deployed in two phases. The first phase takes around 30 minutes and builds most of the environment. An AWS account with an IAM admin role (typically using the AWS-managed Administrator Access policy) is required, but Falcon API credentials are not required for this step. Once deployed, there are a few manual steps required to deploy the Falcon components in phase two described on the next page. Note: In a production environment, once the Falcon API credentials have been created, the entire build process can be automated. See https://github.com/CrowdStrike/cloud-fcs-labs for more information. Self-guided lab users will need to build their own lab environment from start to finish, and should refer to the optional lab environment build instructions on the Getting Started page. While the CloudFormation stacks are provisioning, existing CrowdStrike Falcon Cloud Security subscribers should generate an API key for the next step. If you are attending a hosted or instructor-led event where an AWS lab environment is provided for you, you will be given a set of API credentials valid for the duration of the event.

The first phase CloudFormation build provisions the following components:

- **EKS cluster, nodegroups, and IRSA roles** - running vulnerable web app and Falcon protection components
- **EC2 Bastion host** - to interact with EKS cluster and AWS services
- **EC2 Kali/Metasploit host** - to demonstrate runtime attack
- **IAM roles** for service-level operations
- **Lambda functions** for setup and teardown.
- **AWS Developer Tools CodeCommit pipeline** - container image build/scan/deploy
- **AWS Elastic Container Registry (ECR)** for Falcon sensor and Tomcat container images
- **AWS WAF** - associated with web app Application Load Balancer, in non-blocking mode
- **Falcon Cloud Security Posture Management** - API-based, agentless protection (optional)
- **Falcon Cloud Security Cloud Workload Protection** - agent-based components deployed to EKS
- **Falcon Cloud Security Pre-runtime Image Scanning** - CI/CD scanning of new container images
- **Tomcat** container specifically to Kali instance on port 80 (not otherwise accessible from the public internet) by **Application Load Balancer** ingress
- An assortment of misconfigured AWS services (optional)

Architectural diagram for the lab scenario

![AWS architectural diagram of the lab](lab-diagram.svg)

## Additional notes on the lab environment

Building infrastructure in CloudFormation is easy, building complex and secure infrastructure where components tie together is complicated. One benefit of using Infrastructure-as-Code is that the intended result is always documented and incremental improvements are incorporated into future deployments.

**Kali access control:**

Kali is a powerful platform used for penetration testing, white-hat hacking, and probably more nefarious purposes. As such, access should be restricted from external access. In prior versions of this lab, Kali was access over SSH via shared key. In this version, the use of SSM Session Manager Connect simplifies network access control by using IAM and AWS Account access to govern access to Kali (and the Bastion host).

**Vulnerable webapp access control:**

We deploy a vulnerable Tomcat webapp which would typically be open to anonymous internet traffic. We demonstrate how easy it is to find and exploit this vulnerability. This must not be exposed to the internet (especially in the absence of Falcon runtime protection). In this case, AWS Security Groups are used to restrict access so that only Kali can access the vulnerable application, and (aside from SSM Session Manager Connect), only resources egressing through the lab environment’s NAT gateway can access Kali.
