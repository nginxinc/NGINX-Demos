#!/bin/bash

docker ps -a | grep random-nginx-demo | grep Exit | awk '{print $1}' | xargs docker start


