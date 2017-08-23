#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Create the service1 service.

source constants.inc
docker service create --endpoint-mode dnsrr --name service1 --replicas 3 --network appnetwork --detach=true ${dockerPrefix}service1
