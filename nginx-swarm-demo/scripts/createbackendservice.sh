#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Create the backend-app service.

source constants.inc
docker service create --name backend-app --replicas 3 --network appnetwork ${dockerPrefix}hello
