#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Generate a fixe amount of load.
#
# There are 2 input parameters: number of connections and duration 

source constants.inc

# Get the IP of the Docker host to
ip=`ifconfig docker0 | grep "inet addr" | awk -F '[: ]+' '{print $4}'`

# Set bash to exit after SIGINT, otherwise ctrl-c won't stop the script
trap "exit" INT

echo "duration=$duration connections=$connections"
siege -t ${2}s -c $1 -d 1 http://${ip}/service1.php
