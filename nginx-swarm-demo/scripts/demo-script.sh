##/usr/bin/env bash
#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Runs the scripted demo commands

cd "${BASH_SOURCE%/*}"

source constants.inc

. demo-magic.sh

# speed at which to simulate typing. bigger num = faster
TYPE_SPEED=15

# custom prompt
DEMO_PROMPT="\u@\h:~# "

clear

# Demo Script

#########################
##### Demo 1: Swarm #####
#########################
demo_1 () {
    # 1. Show Swarm Cluster
    pe "docker node ls"

    # 2. Create the backend service
    pe "docker service create --name backend-app-swarm -p 8085:80 --replicas 3 ${dockerPrefix}hello"

    # 3. Show the service list
    pe "docker service ls"

    # 4. Show the tasks
    pe "docker service ps backend-app-swarm"

    # 5. Show a container
    pe "docker ps"

    # 6. Scale the service
    pe "docker service scale backend-app-swarm=5"

    # 7. Show that the service scaled
    pe "docker service ps backend-app-swarm"

    # 8. Show load balancing 1
    pe "curl -s http://${demoHost}:8085 | grep address"

    TYPE_SPEED=250

    # 9. Show load balancing 2
    pe "curl -s http://${demoHost}:8085 | grep address"

    # 10. Show load balancing 3
    pe "curl -s http://${demoHost}:8085 | grep address"

    # 11. Show load balancing 4
    pe "curl -s http://${demoHost}:8085 | grep address"

    # 12. Show load balancing 5
    pe "curl -s http://${demoHost}:8085 | grep address"

    TYPE_SPEED=15

    # 13. Delete the backend service
    pe "docker service rm backend-app-swarm"

    # 14. Show the service list
    pe "docker service ls"
}

###############################
##### Demo 2: NGINX F/OSS #####
###############################
demo_2 () {
    # 1. Create the overlay network
    pe "docker network create -d overlay appnetwork"

    # 2. Show the network list
    pe "docker network ls"

    # 3. Create the backendservice
    pe "docker service create --name backend-app --replicas 3 --network appnetwork ${dockerPrefix}hello"

    # 4. Create the NGINX F/OSS service
    pe "docker service create --name nginx --replicas 1 -p 8090:80 -p 9443:443 --network appnetwork ${dockerPrefix}nginxbasic"

    # 5. Show the service list
    pe "docker service ls"

    # 6. Show the tasks
    pe "docker service ps backend-app"

    # 7. Show HTTP load balancing 1
    pe "curl -s http://${demoHost}:8090 | grep address"

    TYPE_SPEED=250

    # 8. Show HTTP load balancing 2
    pe "curl -s http://${demoHost}:8090 | grep address"

    # 9. Show HTTP load balancing 3
    pe "curl -s http://${demoHost}:8090 | grep address"

    TYPE_SPEED=15

    # 10. Show HTTPS load balancing 1
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    TYPE_SPEED=250

    # 11. Show HTTPS load balancing 2
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    # 12. Show HTTPS load balancing 3
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    TYPE_SPEED=15

    # 13. Show the nginx configuration
    pe "vim ../nginxbasic/backend.conf"

    # 14. Scale the service
    pe "docker service scale backend-app=5"

    # 15. Show that the service scaled
    pe "docker service ps backend-app"

    # 16. Show HTTPS load balancing 1
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    TYPE_SPEED=250

    # 17. Show HTTPS load balancing 2
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    # 18. Show HTTPS load balancing 3
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    # 19. Show HTTPS load balancing 4
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    # 20. Show HTTPS load balancing 5
    pe "curl -s -k https://${demoHost}:9443 | grep address"

    TYPE_SPEED=15

    # 21. Remove the services
    pe "docker service rm nginx backend-app"

    # 22. Remove the overlay network
    pe "docker network rm appnetwork"
}

#####################################
##### Demo 3: NGINX Plus Part 1 #####
#####################################
demo_3 () {
    # 1. Create the overlay network
    pe "docker network create -d overlay appnetwork"

    # 2. Create the service1 service
    pe "docker service create --endpoint-mode dnsrr --name service1 --replicas 3 --network appnetwork ${dockerPrefix}service1"

    # 3. Create the service2 service
    pe "docker service create --endpoint-mode dnsrr --name service2 --replicas 3 --network appnetwork ${dockerPrefix}service2"

    # 4. Create the etcd service
    pe "docker service create --endpoint-mode dnsrr --name etcd --replicas 1 --network appnetwork ${dockerPrefix}etcd"

    # 5. Create the NGINX Plus service
    pe "docker service create --name nginxplus --replicas 1 -p 80:80 -p 443:443 -p 8081:8081 -p 2379:2379 --network appnetwork ${dockerPrefix}nginxplus"

    # 6. Show the services
    pe "docker service ls"

    # 7. Show the service1 tasks
    pe "docker service ps service1"

    # 8. Show the service2 tasks
    pe "docker service ps service2"

    # 9. Show the etcd tasks
    pe "docker service ps etcd"

    # 10. Show the NGINX Plus tasks
    pe "docker service ps nginxplus"

    # 11. Show NGINX Plus dashboard
    # Browser: http://swarmdemo:8081

    # 12. Show service2
    # Browser: http://swarmdemo/service2.php

    # 13. Show service1
    # Browser: http://swarmdemo/service1.php

    # 14. Generate load
    # Shell: runsiege.sh

    # 15. Show NGINX Plus dashboard
    # Browser: http://swarmdemo:8081

    # 16 Scale the services up
    pe "docker service scale service1=5 service2=5"

    # 17. Show NGINX Plus dashboard
    # Browser: http://swarmdemo:8081

    # 18. Show the NGINX Plus configuration
    pe "vim ../nginxplus/backend.conf"
}

#####################################
##### Demo 4: NGINX Plus Part 2 #####
#####################################
# 1. Run autoscale.py for service1
# Shell: autoscale.py

# 2. Run autoscale.py for service2
# Shell: autoscale.py -s service2

# 3. Show NGINX Plus dashboard
# Browser: http://swarmdemo:8081

# 4. Cause a health check to fail
# Shell: seterror.sh CONTAINER_IP_ADDRESS

# 5. Fix the health check
# Shell: fixerror.sh CONTAINER_IP_ADDRESS

################
##### Main #####
################

if [ $1 ]; then
    if [ "$1" -eq "$1" ] 2> /dev/nullecho; then
        if [ "$1" -ge 1 ] && [ "$1" -le 3 ]; then
            startingDemo=$1
        else
            echo "Input must be an integer between 1 and 3.  Defaults to 1."
            exit 1
        fi
    fi
else
    startingDemo=1
fi

if [ "$startingDemo" -eq 1 ]; then
    demo_1
fi
if [ "$startingDemo" -le 2 ]; then
    demo_2
fi
if [ "$startingDemo" -le 3 ]; then
    demo_3
fi

# show a prompt after the demo has concluded
p ""
