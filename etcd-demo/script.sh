#!/bin/bash
if [[ -z "$HOST_IP" ]]; then
  echo "HOST_IP not set in etcd container. Setting it to 10.2.2.70 (IP address assigned in the Vagrantfile)"
  HOST_IP=10.2.2.70
fi

# HOST_IP=$(ip -f inet a show enp0s8 | grep -oP "(?<=inet ).+(?=\/)")
CURL='/usr/bin/curl'
OPTIONS='-s'
ETCD_KEYS_API="http://$HOST_IP:4001/v2/keys"
ETCD_MACHINES_API="http://$HOST_IP:4001/v2/machines"
STATUS_UPSTREAMS_API="http://$HOST_IP:8080/api/3/http/upstreams"

# Get the list of current NGINX upstreams
upstreams=$($CURL $OPTIONS $STATUS_UPSTREAMS_API | jq -r '. as $in | keys[]')
servers=$($CURL $OPTIONS ${STATUS_UPSTREAMS_API}/${upstreams}/servers)
echo "NGINX upstreams in $upstreams:"
echo $servers

# Get the IP etcd is listening on
endpoint=$($CURL $OPTIONS $ETCD_MACHINES_API)
echo "endpoint=$endpoint"
IFS=':/' read -ra list <<< "$endpoint"    #Convert string to array
etcdip=${list[3]}
echo "etcdip=$etcdip"

# Check for ETCD_WATCH_ACTION & act accordingly
if [[ $ETCD_WATCH_ACTION == "set" ]]; then
  IFS=':' read -ra list <<< "$ETCD_WATCH_VALUE"    #Convert string to array
  port=${list[1]}
  entry=$etcdip:$port
  $CURL -X POST -d '{"server": "'$entry'"}' $OPTIONS "${STATUS_UPSTREAMS_API}/${upstreams}/servers"
  echo "Added $entry to the NGINX upstream group $upstreams!"

elif [[ $ETCD_WATCH_ACTION == "delete" ]]; then
  # Loop through the NGINX upstreams and remove the ones not present in etcd
  servers=($($CURL $OPTIONS ${STATUS_UPSTREAMS_API}/${upstreams}/servers | jq  -c '.[]'))
  for params in ${servers[@]}; do
    if [[ $params =~ "server" ]]; then
      server=$(echo $params | jq '.server')
      continue
    elif [[ $params =~ "id" ]]; then
      id=$(echo $params | jq '.id')
    else
      continue
    fi

    # Loop through the servers in etcd & check if $server exists
    ports=$($CURL $OPTIONS $ETCD_KEYS_API/http | jq --raw-output '.node.nodes[].value')
    found=0
    for port in ${ports[@]}; do
      entry=$etcdip$port
      if [[ $server =~ $entry ]]; then
        echo "$server matches etcd entry $entry"
        found=1
        break
      else
        continue
      fi
    done

    if [ $found -eq 0 ]; then
      $CURL -X DELETE $OPTIONS "{$STATUS_UPSTREAMS_API}/$upstreams/servers/$id"
      echo "Removed $server # $id from NGINX upstream block $upstreams!"
    fi
  done
fi
