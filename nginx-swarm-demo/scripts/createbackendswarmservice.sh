#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Create the backend-app-swarm service.

source constants.inc
docker service create --name backend-app-swarm -p8085:80 --replicas 3 ${dockerPrefix}hello
