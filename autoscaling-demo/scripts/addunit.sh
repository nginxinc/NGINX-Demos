#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demoonstration purposes only
#
# Create multiple NGINX Unit containers and add them to
# the upstream group.
#
# There is one input parameter, the number of servers to create.

# The name of NGINX Plus upstream group
upstream="unit_backends"
# The Docker image to use for container
image="nginxunit"
# The port to be mapped
port=9080

if [ $1 ]; then
    count=$1
    if [ "$count" -ne "$count" ] 2>/dev/null; then
        count=1
    fi
else
    count=1
fi

until [  $count -lt 1 ]; do
    let count-=1
    ./addnode.sh $upstream $image $port
done
