#!/bin/bash
etcdctl --no-sync --endpoint http://$HOST_IP:4001 exec-watch --recursive / -- sh -c ./script.sh;
