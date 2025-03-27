---
title: "Getting Started"
weight: 30
---

Building infrastructure in CloudFormation is easy, building complex and secure infrastructure where components tie together is complicated. One benefit of using Infrastructure-as-Code is that the intended result is always documented and incremental improvements are incorporated into future deployments.

**1. Kali access control:**

Kali is a powerful platform used for penetration testing, white-hat hacking, and probably more nefarious purposes. As such, access should be restricted from external access. In prior versions of this lab, Kali was access over SSH via shared key. In this version, the use of SSM Session Manager Connect simplifies network access control by using IAM and AWS Account access to govern access to Kali (and the Bastion host).

**2. Vulnerable webapp access control:**

We deploy a vulnerable Tomcat webapp which would typically be open to anonymous internet traffic. We demonstrate how easy it is to find and exploit this vulnerability. This must not be exposed to the internet (especially in the absence of Falcon runtime protection). In this case, AWS Security Groups are used to restrict access so that only Kali can access the vulnerable application, and (aside from SSM Session Manager Connect), only resources egressing through the lab environment’s NAT gateway can access Kali.

**3. AWS CodeBuild/CodePipeline:**

CodePipeline allows automation of a wide variety of build tasks, triggered by changes to a source code repository. In this environment, CodePipeline allows us to centralize multi-language builds within CloudFormation. In the deployInfra stack, CodeBuild launches eksctl tasks to build the cluster, nodegroup, OIDC federation, and IRSA (IAM Roles for Service Accounts) roles. We could just as easily use Terraform or other IaC languages in the CodeBuild environment. In the deployFalcon stack, we can simplify even potentially complex deployment workflows. Deployment of Falcon Cloud Security runtime protection (aka Cloud Workload Protection for Containers) entails multiple steps including modifying manifest files to include Falcon API key credentials and customer identifiers, deployment of an Operator, and a Helm chart which also includes adding Helm repositories with customized values. Doing all this manually is not terribly difficult but it breaks the automation, is susceptible to error, and is time-consuming toil. Creating CodeBuild jobs is also not very difficult and made more accessible by CrowdStrike offering these sample templates.

Login to Falcon console to confirm the AWS account is registered and CSPM is enabled for the account

URL: https://falcon.crowdstrike.com/cloud-security/registration-v2/aws

![Screenshots of Falcon cloud account registration](/static/img/account-reg.png)
