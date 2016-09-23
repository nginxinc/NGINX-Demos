#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Pulls all the Docker images from a Docker repo. There is no need
# to do this if the images are built and stored in the local repo.
# If they are built on one node and pushed to a Docker repo  then
# pulling them explicitly will speed up the demo the first time
# it is run, but it is not required.
#
# The value to prefix the Docker images with must be specified in
# the variable, dockerPrefix, in the constants.inc file.

source constants.inc
source checkdockerlogin.inc

if ! checkDockerLogin "push"; then
    exit 1
fi

docker pull ${dockerPrefix}hello
docker pull ${dockerPrefix}nginxbasic
docker pull ${dockerPrefix}phpfpmbase
docker pull ${dockerPrefix}service1
docker pull ${dockerPrefix}service2
docker pull ${dockerPrefix}nginxplus
docker pull ${dockerPrefix}etcd
