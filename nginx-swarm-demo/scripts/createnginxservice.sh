#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Create the nginx service.

source constants.inc
docker service create --name nginx --replicas 1 -p 8090:80 -p 9443:443 --network appnetwork ${dockerPrefix}nginxbasic
