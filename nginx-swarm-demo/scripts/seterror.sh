#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Sets the health status for a service1 container to fail by adding
# an entry to etcd using the container’s IP address as the key.
#
# There is 1 input parameter: The IP address of the container

source constants.inc

if ! [ $1 ]; then
    echo "Usage: seterror.sh CONTAINER_IP_ADDRESS"
    exit 1
fi

curl http://${demoHost}:2379/v2/keys/$1 -XPUT
