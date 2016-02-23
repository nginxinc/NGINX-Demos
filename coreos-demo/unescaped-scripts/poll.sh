#!/bin/bash

NGINX_ENDPOINT=127.0.0.1:8081

SERVERS=$(etcdctl ls /services/backend --recursive | awk -F/ '{print $NF}')

for s in $SERVERS
do
   curl "$NGINX_ENDPOINT/upstream_conf?upstream=backend&add=&server=$s"
done