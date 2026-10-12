#!/usr/bin/env bash
# Starts Blog in RESTgym: see /infrastructure/api/restgym-api.sh

source /infrastructure/api/restgym-api.sh
source /infrastructure/api/restgym-mysql.sh

RESTGYM_PROXY_SCRIPTS=(/api/auth.py)

# MySQL, with the database created when the image is built (init-mysql.sh)
restgym_start_mysql

restgym_run_api 8080 \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -jar /api/blog-sut.jar
