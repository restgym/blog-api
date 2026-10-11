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
    apt -y autoremove && \
    rm -rf /var/lib/apt/lists/*

# MySQL database, created when the image is built (see init-mysql.sh and infrastructure/api/restgym-mysql.sh)
RUN bash /api/init-mysql.sh

# Startup script: starts the API, the collection of code coverage and the proxy (see infrastructure/api/restgym-api.sh)
COPY ./apis/blog/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["bash", "/entrypoint.sh"]
