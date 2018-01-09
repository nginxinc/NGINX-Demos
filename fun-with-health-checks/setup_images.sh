#!/bin/bash
# Copyright (C) 2017 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Builds the NGINX Plus and NGINX/PHP-FPM containers and pulls
# the Consul and Registrator images.
#
# By default, the images are only built if they don't exist.
# The -f flag is used to force them to be built.

if [ "$1" = "-f" ]; then
    docker build -t bhc-nginxplus nginxplus
    docker build -t bhc-unit unit
else
    n=`docker images | grep bhc-nginxplus`
    if [ "$n" ]; then
        echo "bhc-nginxplus exist.  Do not build."
    else 
        echo "bhc-nginxplus does not exist.  Build."
        docker build -t bhc-nginxplus nginxplus
    fi
    n=`docker images | grep bhc-unit`
    if [ "$n" ]; then
        echo "bhc-unit exist.  Do not build."
    else 
        echo "bhc-unit does not exist.  Build."
        docker build -t bhc-unit unit
    fi
fi
docker pull gliderlabs/registrator
docker pull progrium/consul
