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
upstreamInfo=`curl -s http://localhost:8080/api/3/http/upstreams/$upstream | jq '.peers[-1]'`
if [ ! "$upstreamInfo" ]; then
    # There are no upstream servers
    exit 1
fi
# Get the node id
node=`echo $upstreamInfo | jq '.id'`
if [ "$node" != "" ]; then
    # Get the port
    port=`echo $upstreamInfo | jq --raw-output '.server' | awk -F\: '{print $2}'`
    if [ "$port" != "" ]; then
        cid=`docker ps | grep $port | awk '{print $1}'`
        if [ "$cid" != "" ]; then
            echo "Remove node $node from upstream $upstream"
            # Remove the upstream server
            curl -s -X DELETE "http://localhost:8080/api/3/http/upstreams/$upstream/servers/$node"
            echo -e "\nRemove $upstream container $cid"
            # Remove the container
            docker rm -f $cid
            exit 0
        fi
    fi
fi
echo "There was an error"
exit 1
