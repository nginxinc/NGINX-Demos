#!/bin/bash
# Create a script to remove unneeded Docker images
docker images | grep "<none>" | awk '{print "docker rmi " $3}' > rmi.sh
