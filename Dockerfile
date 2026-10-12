# Blog
# Base image: Ubuntu 22.04, Java 11 (headless JRE), mitmproxy and the RESTgym infrastructure (see infrastructure/api/Dockerfile)
FROM restgym-api-base:java11

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        mysql-server \
    && rm -rf /var/lib/apt/lists/*

# The API: its executable, the classes for code coverage, its specifications and scripts
COPY ./apis/blog/ /api/

# MySQL database, created when the image is built (see init-mysql.sh and infrastructure/api/restgym-mysql.sh)
RUN bash /api/init-mysql.sh

# Startup script (in /api): starts the API, the collection of code coverage and the proxy (see infrastructure/api/restgym-api.sh)
ENTRYPOINT ["bash", "/api/entrypoint.sh"]
