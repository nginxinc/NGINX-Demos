#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Generates load.  Loop forever.  For each iteration, randomly 
# generate the duration and number of connections.  The host name
# is gotten from constants.inc.

source constants.inc

minDuration=5
maxDuration=15
minConnections=1
maxConnections=50

# Set bash to exit after SIGINT, otherwise ctrl-c won't stop the script
trap "exit" INT

while [ true ]; do
    duration=`shuf -i${minDuration}-${maxDuration} -n1`
    connections=`shuf -i${minConnections}-${maxConnections} -n1`
    echo "duration=$duration connections=$connections"
    siege -t ${duration}s -c $connections -d 1 http://${demoHost}:8080/service1.php
done
