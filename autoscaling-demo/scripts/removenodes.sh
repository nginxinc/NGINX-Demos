#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Removes multiple upstream servers and their containers.

# There are two input parameters: The upstream group (default nginx_backends)
# and the number of servers to remove (default 1)

if [ $1 ]; then
    upstreamGroup=$1
    if [ $2 ]; then
        count=$2
        if [ "$count" -ne "$count" ] 2>/dev/null; then
            count=1
        fi
    else
        count=1
    fi
else
    upstreamGroup="nginx_backends"
fi

until [  $count -lt 1 ]; do
    let count-=1
    ./removenode.sh $upstreamGroup
done
