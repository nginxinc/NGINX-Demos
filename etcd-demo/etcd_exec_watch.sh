#!/bin/bash
HOST_IP=$(ip -f inet a show enp0s8 | grep -oP "(?<=inet ).+(?=\/)")
etcdctl --no-sync --endpoint http://$HOST_IP:4001 exec-watch --recursive / -- sh -c /srv/NGINX-Demos/etcd-demo/script.sh;
