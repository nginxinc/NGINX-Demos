#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Creates a container and adds it to an upstream group.
#
# There are 3 input parameters: upstream, image and port

if [ $1 ]; then
    upstream=$1
    if [ $2 ]; then
        image=$2
        if [ $3 ]; then
            port=$3
        else
            echo "Usage: addnode.sh UPSTREAMGROUP IMAGE PORT"
            exit 1
        fi
    else
        echo "Usage: addnode.sh UPSTREAMGROUP IMAGE PORT"
        exit 1
    fi
else
    echo "Usage: addnode.sh UPSTREAMGROUP IMAGE PORT"
    exit 1
fi

# The IP of Docker host to use for upstream server as $id
source dockerip
# Create the container
cid=`docker run -P -d $image`
# Get the mapped port 
mapport=`docker port $cid $port | awk -F : '{print $2}'`
echo "Container created: $cid Port: $mapport"
# Add the node to the upstream group
addnode=`curl -s http://localhost/upstream_conf?add=\&upstream=$upstream\&server=$ip:$mapport`
echo "Node added: $addnode"
