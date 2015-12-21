#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Switches the healthcheck.html page to the error version 
# for an NGINX Plus web server instance.
#
# There is 1 input parameter: port
if [ $1 ]; then
    port=$1
else
    echo "Usage: seterror.sh PORT"
    exit 1
fi

# Find the container matching the port
container=`docker ps | awk "/nginxplusws/ && /$port/" | awk '{ print $1 }'`
if [ $container ]; then
    echo "port=$port container=$container"
    #exit 0
    # Copy the health check file to cause the health check to fail
    docker exec -i -t $container cp /usr/share/nginx/html/healthcheck.html.err /usr/share/nginx/html/healthcheck.html
    echo "Introduce error to container $container on port $port"
else
    echo "No container found for port $port"
fi
