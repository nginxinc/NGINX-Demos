#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Create an NGINX Plus container using the configuration files in
# ../nginx_config, mapped to /etc/nginx in the container and the
# web content in ../nginx_www, mapped to /usr/share/nginx/html.
# Map ports from the container to the same ports on the host.

# Docker wants absolute paths
config=`cd ../nginx_config; pwd`

cid=`docker run --name mynginxplus -v $config:/etc/nginx/conf.d:ro -p 80:80 -p 8080:8080 -p 443:443 -p 9080:9080 -d nginxpluslb`
echo "Container created: $cid"
