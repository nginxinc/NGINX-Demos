#!/bin/bash
# Copyright (C) 2019 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Create multiple containers and add them to an upstream group.
#
# There are four input parameters: The upstream group, the Docker image, the
# port and the number of servers to remove (default 1).  The first three
# parameters are required.

requiredInput=0

if [ $1 ]; then
    upstreamGroup=$1
    if [ $2 ]; then
        image=$2
        if [ $3 ]; then
            port=$3
            if [ "$port" -eq "$port" ] 2>/dev/null; then
                requiredInput=1
            fi
            if [ $4 ]; then
                count=$4
                if [ "$count" -ne "$count" ] 2>/dev/null; then
                    count=1
                fi
            else
                count=1
            fi
        fi
    fi
fi

if [ "$requiredInput" -eq 1 ]; then
    until [  $count -lt 1 ]; do
        let count-=1
        ./addnode.sh $upstreamGroup $image $port
    done
else
    echo "Input error.  Usage: addnode.sh <upstreamGroup> <Docker image> <Port> [Count=1]"
fi
