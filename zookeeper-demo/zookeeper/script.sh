#!/bin/bash
if [[ -z "$HOST_IP" ]]; then
  echo "HOST_IP not set inside zookeeper container. Setting it to 10.2.2.70 (IP address assigned in the Vagrantfile)"
  HOST_IP=10.2.2.70
fi

CURL='/usr/bin/curl'
OPTIONS='-s'
ZK_LIST_SERVICES="./zk-tool list /services"
STATUS_UPSTREAMS_API="http://$HOST_IP:8080/api/3/http/upstreams"

# Get the list of current NGINX upstreams
upstreams=$($CURL $OPTIONS $STATUS_UPSTREAMS_API | jq -r '. as $in | keys[]')
servers=$($CURL $OPTIONS ${STATUS_UPSTREAMS_API}/${upstreams}/servers)
echo "NGINX upstreams in $upstreams:"
echo $servers

# Loop through the registered servers in ZK tagged with production (i.e backend servers to be proxied through nginx)
# add the ones not present in the NGINX upstream block
echo "Servers registered with ZK:"
ip=$HOST_IP
ports=$($ZK_LIST_SERVICES | grep production | jq '.PublicPort')
for port in $ports; do
  entry=$ip:$port
  echo $entry
  if [[ ! $servers =~ $entry ]]; then
    $CURL -X POST -d '{"server": "'$entry'"}' $OPTIONS "${STATUS_UPSTREAMS_API}/${upstreams}/servers"
    echo "Added $entry to the nginx upstream group $upstreams!"
  fi
done

# Loop through the NGINX upstreams and remove the ones not present in ZK
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

  ports=$($ZK_LIST_SERVICES | grep production | jq '.PublicPort')
  found=0
  for port in $ports; do
    entry=$ip:$port
    if [[ $server =~ $entry ]]; then
      echo "$server matches zk entry $entry"
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
