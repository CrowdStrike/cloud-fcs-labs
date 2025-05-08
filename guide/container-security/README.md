# Container Security

In the previous lab, you exploited an EC2 instance running a vulnerable webapp and saw how Falcon
Cloud Security detected and prevented multiple phases of the attack. This is based on the Falcon
platform's runtime protection. While runtime is a critical phase of application security, DevOps
relies on the "shift left" pattern to surface security protections earlier in the application lifecycle,
so that problems can be prevented before they lead to a breach.

In this lab, we'll focus on how Falcon Cloud Security allows for the pre-runtime assessment of container
images and supports policy enforcement of those container images at deploy-time in Kubernetes. Combining
these capabilities allows DevOps and SecOps teams to work together to keep container-native workloads
secure.
