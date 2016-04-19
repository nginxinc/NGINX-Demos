#!/bin/bash
CURL='/usr/bin/curl'
OPTIONS='-s'
ETCD_KEYS_API="http://$HOST_IP:4001/v2/keys"
ETCD_MACHINES_API="http://$HOST_IP:4001/v2/machines"
STATUS_UPSTREAMS_API="http://$HOST_IP:8080/status/upstreams"
UPSTREAM_CONF_API="http://$HOST_IP/upstream_conf?"

# Get the list of current Nginx upstreams
upstreams=$($CURL $OPTIONS $STATUS_UPSTREAMS_API | jq -r '. as $in| keys[]')
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
    echo "$entry added to NGINX upstream group $upstreams!"
    add_entry=$($CURL $OPTIONS "{$UPSTREAM_CONF_API}add=&upstream=$upstreams&server=$entry")

elif [[ $ETCD_WATCH_ACTION == "delete" ]]; then
    # Loop through the Nginx upstreams and remove the ones not present in etcd 
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
        # Loop through the servers in Etcd & check if $server exists
        services=$(docker ps --filter "label=SERVICE_TAGS=production" --format "{{.Names}}")
        found=0
        for srv in $(echo $services | tr " " "\n"); do
            service=$($CURL $OPTIONS $ETCD_KEYS_API/${srv} | jq --raw-output '.node.nodes[].value')
            if [[ $service =~ "jq: error" ]]; then
                continue
            fi
            IFS=':' read -ra list <<< "$service"    #Convert string to array
            port=${list[1]}
            entry=$etcdip:$port
            if [[ $server =~ $entry ]]; then
                #echo "$server matches etcd $entry"
                found=1
                break
            else
                continue
            fi
        done
        if [ $found -eq 0 ]; then
            remove_entry=$($CURL $OPTIONS "{$UPSTREAM_CONF_API}remove=&upstream=$upstreams&$id")
            echo "$server removed from nginx upstream block $upstreams!"
        fi
    done
fi
