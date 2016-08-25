#!/bin/bash

CONTAINER=service2
echo "Introducing error into $CONTAINER"
docker exec -i -t "$CONTAINER" sed -i s/Hello/GoodBye/g /usr/share/nginx/html/index.html
