#!/bin/bash
if [ ${HOST_IP} ]; then
  echo "HOST_IP=${HOST_IP}"
else
  ipaddr=$(ip -f inet a show enp0s8 | grep -oP "(?<=inet ).+(?=\/)")
  echo "export HOST_IP=$ipaddr" | tee -a ~/.bash_aliases
  . ~/.bash_aliases
  /usr/local/bin/docker-compose -f /srv/NGINX-Demos/zookeeper-demo/docker-compose.yml up -d
fi
