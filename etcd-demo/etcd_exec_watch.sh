#!/bin/bash
# Check if env var HOST_IP is set, set it if its not
if [[ -z "$HOST_IP" ]]; then
    echo "HOST_IP not set on docker host. Setting it to 10.2.2.70 (IP address assigned in the Vagrantfile)"
    HOST_IP=10.2.2.70
fi

/usr/local/bin/etcdctl --no-sync --endpoint http://$HOST_IP:4001 exec-watch --recursive / -- sh -c ./script.sh;
