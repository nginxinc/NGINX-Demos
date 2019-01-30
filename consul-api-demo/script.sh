#!/bin/bash
if [[ -z "$HOST_IP" ]]; then
  echo "HOST_IP not set in consul container. Setting it to 10.2.2.70 (IP address assigned in the Vagrantfile)"
  HOST_IP=10.2.2.70
fi

CURL='/usr/bin/curl'
OPTIONS='-s'
CONSUL_SERVICES_API="http://$HOST_IP:8500/v1/catalog/services"
CONSUL_SERVICE_API="http://$HOST_IP:8500/v1/catalog/service"
STATUS_UPSTREAMS_API="http://$HOST_IP:8080/api/3/http/upstreams"

# Get the list of current NGINX upstreams
upstreams=$($CURL $OPTIONS $STATUS_UPSTREAMS_API | jq -r '. as $in | keys[]')
servers=$($CURL $OPTIONS ${STATUS_UPSTREAMS_API}/${upstreams}/servers)
echo "NGINX upstreams in $upstreams:"
echo $servers

# Loop through the registered servers in consul tagged with production (i.e backend servers to be proxied through nginx) and add the ones not present in the Nginx upstream block
echo "Servers registered with consul:"
service=$($CURL $OPTIONS $CONSUL_SERVICES_API | jq --raw-output 'to_entries | .[] | select(.value[0] == "production") | .key')

ports=$($CURL $OPTIONS $CONSUL_SERVICE_API/$service | jq -r '.[] | .ServicePort')
for port in ${ports[@]}; do
  entry=$HOST_IP:$port
  if [[ ! $servers =~ $entry ]]; then
    $CURL -X POST -d '{"server": "'$entry'"}' $OPTIONS "${STATUS_UPSTREAMS_API}/${upstreams}/servers"
    echo "Added $entry to the NGINX upstream group $upstreams!"
  fi
done

# Loop through the NGINX upstreams and remove the ones not present in consul
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

  service=$($CURL $OPTIONS $CONSUL_SERVICES_API | jq --raw-output 'to_entries| .[] | select(.value[0] == "production") | .key')
  ports=$($CURL $OPTIONS $CONSUL_SERVICE_API/$service | jq -r '.[]|.ServicePort')
  found=0
  for port in ${ports[@]}; do
    entry=$HOST_IP:$port
    if [[ $server =~ $entry ]]; then
      echo "$server matches consul entry $entry"
      found=1
      break
    else
      continue
    fi
  done

  if [ $found -eq 0 ]; then
    $CURL -X DELETE $OPTIONS "{$STATUS_UPSTREAMS_API}/$upstreams/servers/$id"
    echo "Removed $server # $id from nginx upstream block $upstreams!"
  fi
done
