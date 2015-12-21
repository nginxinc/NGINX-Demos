#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Removes an upstream server and its container
#
# There is one input parameter: the upstream group

if [ $1 ]; then
    upstream=$1
else
    echo "Usage: removenode.sh UPSTREAMGROUP"
    exit 1
fi
# Get the upstream data from NGINX Plus for the last upstream server
# extracting a string with the port and node id: "<port>; id=<node id>"
upstreamInfo=`curl -s http://localhost/upstream_conf?upstream=$upstream | tail -n1 | awk -F: '{print $2}'`
if [ ! "$upstreamInfo" ]; then
    # There are no upstream servers
    exit 1
fi
# Get the node id
node=`echo $upstreamInfo | awk '{print $3}'`
if [ "$node" != "" ]; then
    # Get the port
    port=`echo $upstreamInfo | awk -F\; '{print $1}'`
    if [ "$port" != "" ]; then
        cid=`docker ps | grep $port | awk '{print $1}'`
        if [ "$cid" != "" ]; then
            echo "Remove node $node from upstream $upstream"
            # Remove the upstream server
            curl http://localhost/upstream_conf?remove=\&upstream=$upstream\&$node
            echo "Remove $upstream container $cid"
            # Remove the container
            docker rm -f $cid
            exit 0
        fi
    fi
fi
echo "There was an error"
exit 1
