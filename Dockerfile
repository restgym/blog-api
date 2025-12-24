FROM ubuntu:22.04

ENV API=blog
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /api && \
    mkdir /results && \
    mkdir /infrastructure

COPY apis/blog/ /api/
COPY infrastructure/ /infrastructure/

RUN apt update && \
    apt -y upgrade && \
    apt -y install openjdk-11-jdk mysql-server mitmproxy python3-requests && \
    usermod -d /var/lib/mysql/ mysql && \
    /etc/init.d/mysql start && \
    mysql -e "CREATE DATABASE blogapi" && \
    mysql -e "CREATE USER blog@localhost IDENTIFIED BY 'blog'" && \
    mysql -e "GRANT ALL PRIVILEGES ON blogapi.* TO blog@localhost" && \
    mysql blogapi < /api/database/blogapi.sql && \
    apt -y autoremove

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    /etc/init.d/mysql start & \
    sleep 20 && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -jar /api/blog-sut.jar