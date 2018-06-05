#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Removes multiple NGINX Unit upstream servers and their containers.
#
# There is one input parameter, the number of servers to remove.

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
    ./removenode.sh unit_backends
done
