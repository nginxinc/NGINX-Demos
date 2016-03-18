#!/bin/bash
if [[ -z "$HOST_IP" ]]; then
    echo "HOST_IP not set inside zookeeper container. Setting it to 10.2.2.70 (IP address assigned in the Vagrantfile)"
    HOST_IP=10.2.2.70
fi

CURL='/usr/bin/curl'
OPTIONS='-s'
ZK_LIST_SERVICES="./zk-tool list /services"
STATUS_UPSTREAMS_API="http://$HOST_IP:8080/status/upstreams"
UPSTREAM_CONF_API="http://$HOST_IP/upstream_conf?"

# Get the list of current Nginx upstreams
upstreams=$($CURL $OPTIONS $STATUS_UPSTREAMS_API | jq -r '. as $in| keys[]')
servers=$($CURL $OPTIONS {$UPSTREAM_CONF_API}upstream=$upstreams)
echo "Nginx upstreams in upstream group $upstreams:"
echo $servers

# Loop through the registered servers in ZK tagged with production (i.e backend servers to be proxied through nginx)
# add the ones not present in the Nginx upstream block
echo "Servers registered with ZK:"
ip=$HOST_IP
ports=$($ZK_LIST_SERVICES | grep production | jq '.PublicPort')
for port in $ports; do
    entry=$ip:$port
    echo $entry
    if [[ ! $servers =~ $entry ]]; then
	$CURL $OPTIONS "{$UPSTREAM_CONF_API}add=&upstream=$upstreams&server=$entry"
        echo "Added $entry to the nginx upstream group $upstreams!"
    fi
done

# Loop through the Nginx upstreams and remove the ones not present in ZK
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

    ports=$($ZK_LIST_SERVICES | grep production | jq '.PublicPort')
    found=0
    for port in $ports; do
    	entry=$ip:$port
        if [[ $server =~ $entry ]]; then
            #echo "$server matches zk entry $entry"
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
