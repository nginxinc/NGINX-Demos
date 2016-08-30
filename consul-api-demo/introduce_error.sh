#!/bin/bash

CONTAINER=consulapidemo_http_1
echo "Introducing error into $CONTAINER"
docker exec -i -t "$CONTAINER" sed -i s/Hello/GoodBye/g /usr/share/nginx/html/index.html
