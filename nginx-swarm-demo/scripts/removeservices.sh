#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Removes all services.

docker service rm backend-app 2>/dev/null
docker service rm backend-app-swarm 2>/dev/null
docker service rm service1 2>/dev/null
docker service rm service2 2>/dev/null
docker service rm nginxplus 2>/dev/null
docker service rm nginx 2>/dev/null
docker service rm etcd 2>/dev/null
