#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Create the etcd service.

source constants.inc
docker service create --endpoint-mode dnsrr --name etcd --network appnetwork --replicas 1 ${dockerPrefix}etcd
