#!/bin/bash

port=8000

loadbalancer=10.2.2.65:8080

for ip in `ip addr show eth1 | grep "inet " | awk '{print $2}' | sed 's@/.*@@'`; do
	echo ""
	
	echo docker run -p $ip:$port:80 -d random-nginx-demo
	docker run --name nginx$ip -p $ip:$port:80 -d random-nginx-demo
	
	echo curl http://$loadbalancer/add/$ip/$port
	curl http://$loadbalancer/add/$ip/$port

done

