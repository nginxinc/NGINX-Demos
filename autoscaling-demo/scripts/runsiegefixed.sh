#!/bin/bash
#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Loop forever, running siege 

duration=600
connections=2

# The IP of Docker host to use for upstream server as $id
source dockerip

# Set bash to exit after SIGINT, otherwise ctrl-c won't stop the script
trap "exit" INT

while [ true ]; do
    siege -t ${duration}s -c $connections -d 1 http://${ip}/index.html
done
