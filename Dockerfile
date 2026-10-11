FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /api && \
    mkdir /results && \
    mkdir /infrastructure

COPY ./apis/blog/ /api/
COPY ./infrastructure/ /infrastructure/

RUN apt update && \
    apt -y upgrade && \
    apt -y install openjdk-11-jdk mysql-server mitmproxy python3-requests && \
    usermod -d /var/lib/mysql/ mysql && \
    /etc/init.d/mysql start && \
    mysql -e "CREATE DATABASE blogapi" && \
    mysql -e "CREATE USER blog@localhost IDENTIFIED BY 'blog'" && \
    mysql -e "GRANT ALL PRIVILEGES ON blogapi.* TO blog@localhost" && \
    mysql blogapi < /api/database/blogapi.sql && \
    apt -y autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    mysqladmin shutdown

# Startup script: starts the API, the collection of code coverage and the proxy (see infrastructure/api/restgym-api.sh)
COPY ./apis/blog/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["bash", "/entrypoint.sh"]
