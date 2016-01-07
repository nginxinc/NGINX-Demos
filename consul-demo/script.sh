#!/bin/bash
# Check if env var HOST_IP is set, set it if its not
if [[ -z "$HOST_IP" ]]; then
    echo "Error: HOST_IP not set inside consul container. Setting it to 10.2.2.70 (IP address assigned in the Vagrantfile)"
    HOST_IP=10.2.2.70
fi

CURL='/usr/bin/curl'
OPTIONS='-s'
CONSUL_SERVICES_API="http://$HOST_IP:8500/v1/catalog/services"
CONSUL_SERVICE_API="http://$HOST_IP:8500/v1/catalog/service"
STATUS_UPSTREAMS_API="http://$HOST_IP:8080/status/upstreams"
UPSTREAM_CONF_API="http://$HOST_IP/upstream_conf?"

# Get the list of current Nginx upstreams
upstreams=$($CURL $OPTIONS $STATUS_UPSTREAMS_API | jq -r '. as $in| keys[]')
servers=$($CURL $OPTIONS {$UPSTREAM_CONF_API}upstream=$upstreams)
echo "Nginx upstreams in $upstreams:"
echo $servers

# Loop through the registered servers in consul tagged with production (i.e backend servers to be proxied through nginx)
# add the ones not present in the Nginx upstream block
echo "Servers registered with consul:"
services=$($CURL $OPTIONS $CONSUL_SERVICES_API | jq --raw-output 'to_entries| .[] | select(.value[0] == "production") | .key')
for key in ${services[@]}; do
    ip=$($CURL $OPTIONS $CONSUL_SERVICE_API/${key} | jq -r '.[]|.Address')
    port=$($CURL $OPTIONS $CONSUL_SERVICE_API/${key} | jq -r '.[]|.ServicePort')
    entry=$ip:$port
    echo $entry
    if [[ ! $servers =~ $entry ]]; then
	$CURL $OPTIONS "{$UPSTREAM_CONF_API}add=&upstream=$upstreams&server=$entry"
        echo "Added $entry to the nginx upstream group $upstreams!"
    fi
done

# Loop through the Nginx upstreams and remove the ones not present in consul 
servers=$($CURL $OPTIONS {$UPSTREAM_CONF_API}upstream=$upstreams)
for params in ${servers[@]}; do
    if [[ $params =~ ":" ]]; then
        server=$params
        continue
    elif [[ $params =~ "id=" ]]; then
        id=$params
    else
        continue
    fi

    services=$($CURL $OPTIONS $CONSUL_SERVICES_API | jq --raw-output 'to_entries| .[] | select(.value[0] == "production") | .key')
    found=0  
    for key in ${services[@]}; do
        ip=$($CURL $OPTIONS $CONSUL_SERVICE_API/${key} | jq -r '.[]|.Address')
        port=$($CURL $OPTIONS $CONSUL_SERVICE_API/${key} | jq -r '.[]|.ServicePort')
    	entry=$ip:$port
        if [[ $server =~ $entry ]]; then
            #echo "$server matches consul entry $entry"
            found=1
            break
        else
            continue
        fi
	done

    if [ $found -eq 0 ]; then
        $CURL $OPTIONS "{$UPSTREAM_CONF_API}remove=&upstream=$upstreams&$id"
        echo "Removed $server # $id from nginx upstream block $upstreams!"
    fi
done
