#!/bin/bash
# Copyright (C) 2017 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Removes all containers

n=`docker ps -qa`
if [ "$n" ]; then
    docker rm -f `docker ps -qa`
else
    echo "No containers to remove"
fi
