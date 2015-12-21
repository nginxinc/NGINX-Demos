#!/bin/bash
#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Loop forever.  For each iteration, randomly generate the duration and number 
# of connections.

minDuration=5
maxDuration=15
minConnections=1
maxConnections=50

# The IP of Docker host to use for upstream server as $id
source dockerip

# Set bash to exit after SIGINT, otherwise ctrl-c won't stop the script
trap "exit" INT

while [ true ]; do
    duration=`shuf -i${minDuration}-${maxDuration} -n1`
    connections=`shuf -i${minConnections}-${maxConnections} -n1`
    echo "duration=$duration connections=$connections"
    siege -t ${duration}s -c $connections -d 1 http://${ip}/index.html
done
