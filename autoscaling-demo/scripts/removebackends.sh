#!/bin/bash
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Removes all the nodes from the upstream groups and removes their containers.

while ./removenginxws.sh ; do
    echo "Removed NGINX backend"
done

while ./removees.sh ; do
    echo "Removed Elasticsearch backend"
done

