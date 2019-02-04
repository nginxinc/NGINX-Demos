#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Disable session persistence by copying the NGINX Plus
# configuration fie docker.conf.nosp to docker.conf and
# sending a signal to NGINX Plus to reload the config

cp ../nginx_config/demo.conf.nosp ../nginx_config/demo.conf
docker kill --signal="HUP" mynginxplus
