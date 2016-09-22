#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Pushes all the Docker images to a Docker repo. This is 
# not required.  The images can be built on each Swarm node
# using the buildallimages.sh script.
#
# The value to prefix the image name with must be specified
# in the variable, dockerPrefix, in the constants.inc file.
# If this is blank, then the script will exit.

source constants.inc
source checkdockerlogin.inc

if ! checkDockerLogin "push"; then
    exit 1
fi

docker push ${dockerPrefix}hello
docker push ${dockerPrefix}nginxbasic
docker push ${dockerPrefix}phpfpmbase
docker push ${dockerPrefix}service1
docker push ${dockerPrefix}service2
docker push ${dockerPrefix}nginxplus
docker push ${dockerPrefix}etcd
