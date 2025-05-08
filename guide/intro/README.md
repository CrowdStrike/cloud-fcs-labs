# Introduction

Welcome to the CrowdStrike Falcon Cloud Security Workshop!

Falcon Cloud Security is an integrated part of CrowdStrike’s Falcon Platform featuring pre-runtime scanning, agent-based operating system runtime protection, and agentless API detection of cloud service misconfigurations and suspicious behaviors. Falcon Cloud Security events and detections are correlated with telemetry from other Falcon modules to block attacks in real-time, and reduce false positives. When deployed in tandem with AWS automation tools and multi-account landing zones, Falcon Cloud Security helps protect all of your cloud resources as you migrate, build, scale, and innovate on AWS.

> [!TIP]
> To learn more about Falcon Cloud Security features and benefits, go to https://www.crowdstrike.com/platform/cloud-security/ .

The goal of this workshop is to acquaint you with AWS-specific deployment options, deploy an environment to simulate a runtime attack against a vulnerable web application, walk you through the Falcon platform response to the attack, and illustrate how Falcon can help you improve your security posture. The lab may be used as an instructor-led workshop, as an internal enablement tool for new Falcon Cloud Security customers, or as a self-guided experience for Falcon Cloud Security trial users. Details for each scenario are provided in the [Getting Started](30-getting-started.md) section.

Additional labs will build on the skills and capabilities presented in the core “Attack and Respond” section.

You will learn:

- Key components of CrowdStrike’s Falcon Cloud Security suite
- How FCS can be deployed and integrated into your AWS environment using end-to-end CI/CD pipeline automation
- Attack a vulnerable web service progressing from reconnaissance to exploit
- How Falcon Cloud Security improves the security posture of AWS cloud workloads
- AWS EKS workload and cluster protection highlights
- CrowdStrike container image scanning features integrated with a typical AWS DevOps pipeline
- Investigate detections and misconfigurations in the CrowdStrike Falcon Console.
