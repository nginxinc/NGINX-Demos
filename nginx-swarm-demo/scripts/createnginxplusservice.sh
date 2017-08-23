#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Create the nginxplus service.

source constants.inc
docker service create --name nginxplus --replicas 1 -p 80:80 -p 8081:8081 -p 443:443 -p 2379:2379 --network appnetwork --detach=true ${dockerPrefix}nginxplus
