#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Create an environemnt with one NGINX Plus load balancer container, 
# one Elasticsearch container as an upstream server and one NGINX
# Plus container as an upstream server.

./addnginxlb.sh
./addnginxws.sh
./addes.sh
