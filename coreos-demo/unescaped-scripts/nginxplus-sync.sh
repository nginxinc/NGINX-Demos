#!/bin/bash

NGINX_ENDPOINT=127.0.0.1:8081
SERVER=$(echo $ETCD_WATCH_KEY | awk -F/ '{print $NF}')

function get_server_id () {
  ID=$(curl -s "$NGINX_ENDPOINT/upstream_conf?upstream=backend" | awk -v server="$SERVER;" '$2==server { print $4 }')
  echo $ID
}


if [ $ETCD_WATCH_ACTION == 'set' ]
then
  echo "Adding $SERVER server"

  ID=$(get_server_id)
  if [ -z $ID ]
  then
    curl -s "$NGINX_ENDPOINT/upstream_conf?upstream=backend&add=&server=$SERVER"
  fi
elif [ $ETCD_WATCH_ACTION == 'delete' ] || [ $ETCD_WATCH_ACTION == 'expire' ]
then
  echo "Removing $SERVER server"
  ID=$(get_server_id)
  echo "Server has $ID"
  curl -s "$NGINX_ENDPOINT/upstream_conf?upstream=backend&remove=&$ID"
fi
