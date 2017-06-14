#!/bin/bash

if [ ${HOST_IP} ]; then
        ipaddr=${HOST_IP}
else
        ipaddr=`/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`
fi
echo "export HOST_IP=$ipaddr" | tee -a ~/.bash_aliases
. ~/.bash_aliases
/usr/local/bin/docker-compose up -d
