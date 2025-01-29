FROM public.ecr.aws/ubuntu/ubuntu:18.04
RUN apt-get -yqq update
RUN apt-get -yqq install openjdk-8-jdk wget net-tools curl unzip python3.5 python3-pip
RUN pip3 install cryptography==2.1.4
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
RUN mkdir /opt/tomcat \
&& cd /opt/tomcat \
&& wget -q http://provisioning.aws.cs-labs.net/workshop/cwp/files/apache-tomcat-8.0.32.tar.gz -O apache-tomcat-8.0.32.tar.gz \
&& wget -q http://provisioning.aws.cs-labs.net/workshop/cwp/files/teds-web.xml -O teds-web.xml \
&& wget -q https://raw.githubusercontent.com/jhseceng/ct-test/main/staging.txt -O staging.txt \
&& tar zxvf apache-tomcat-8.0.32.tar.gz \
&& cp teds-web.xml /opt/tomcat/apache-tomcat-8.0.32/conf/web.xml \
&& mkdir s3data \
&& mv staging.txt s3data\staging.txt \
&& echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64" >> ~/.bashrc \
&& echo "export CATALINA_HOME=/opt/tomcat/apache-tomcat-8.0.32" >> ~/.bashrc
CMD ["/opt/tomcat/apache-tomcat-8.0.32/bin/catalina.sh", "run"]
EXPOSE 8080