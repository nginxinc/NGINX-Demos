#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Removes all containers.

containers=`docker ps -a -q`
if [ "$containers" ]; then
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
else
    echo "No containers to remove"
fi
