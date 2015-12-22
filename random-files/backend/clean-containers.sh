#!/bin/bash

# Usage: ./clean-containers [--rmi]
# If you use a parameter it will also clean ALL container images
 

docker ps -a -q -f name=nginx | xargs docker stop
docker ps -a -q -f name=nginx | xargs docker rm

[ -z $1 ] || docker rmi random-nginx-demo

