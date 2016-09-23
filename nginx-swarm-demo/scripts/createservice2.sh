#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Create the service2 service.

source constants.inc
docker service create --endpoint-mode dnsrr --name service2 --replicas 3 --network appnetwork ${dockerPrefix}service2
