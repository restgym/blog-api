#!/bin/sh
set -e

# Make directory for results
mkdir -p "/results/$API/$TOOL/$RUN"

# Start MySQL in background
/etc/init.d/mysql start

# Wait until MySQL is ready on TCP
echo "Waiting for MySQL to be ready..."
until mysqladmin ping -h127.0.0.1 --silent; do
  sleep 2
done
echo "MySQL is up."

# Start JaCoCo collector in background
sh /infrastructure/jacoco/collect-coverage-interval.sh &

# Start mitmproxy in background
mitmdump -p 9090 --mode reverse:http://localhost:8080/ \
  -s /infrastructure/mitmproxy/store-interactions.py \
  -s /api/auth.py &

# Finally start Spring Boot (PID 1 stays java)
exec java \
  -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
  -Dfile.encoding=UTF-8 \
  -jar /api/blog-sut.jar