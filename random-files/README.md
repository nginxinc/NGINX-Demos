# Demo to show random content and upstream_conf

We have two systems to configure. One is a backend.
In order to simulate multiple backends we will create a dozen of network interfaces
and configure docker containers on each of the interfaces.

On the frontend system we will configure NGINX Plus with several features:
* Load balancing
* Status
* upstream_conf
* health_check

## System requirements and setup

### Backend
Ubuntu 14.04 (probably will work with other systems)

Make sure docker.io is installed

Find out which network interfaces are used to communicate between your VMs.
It will most probably be eth1 for Virtualbox and VMWare and eth0 for Parallels.

Add multiple network interface aliases:
* Edit interfaces.example according to your local network
* If using eth1 interface instead of eth0 edit the interface name in this file
* Replace /etc/network/interfaces with interfaces.example

Prepare you run-containers.sh script:
* Modify the IP addresses according to your network
* Change eth0 to eth1 if needed

## Frontend

Ubuntu 14.04 (or anything that supports nginx-plus-r6 and later)

1. Install nginx-plus or nginx-plus-extras
2. Copy nginx.conf to the system
3. Make sure nginx starts

# Customer interaction script

* Show that we have a backend system and a frontend system.
* Show that our nginx.conf has an empty upstream configured.
* Show the production webpage in a failed/empty state. Leave it on the screen.
* Show the dashboard page (:8080) and demonstrate that it does not have any backends.
* Run the container build. If the customer is tech-savvy show the Dockerfile.
```
./build-containers.sh
```
* Show the script for running the containers. Explain exactly what will happen next: we are going to start that container on every IP in the system and expose port 8000. After starting each container we will issue a curl request to the load balancer and NGINX Plus will use the feature of Dynamic Reconfiguration in order to add those containers to the upstream group. This will be done with no configuration file changes and no worker process restarts. Please see the curl command inside the script. It is that easy.
```
./run-containers.sh
```
* Show the changes in the status page (dashboard). Containers should appear immediately.
* Show the content page.
* Optionally stop one or two containers to demonstrate how health checks take the server offline and it does not disrupt traffic flow.
* Show the output of the listing feature in upstream_conf:
```
curl http://frontend:8080/list
```
Mention that the output is formatted as a configuration file.
* Show the json output for status (using a browser or command line)
* Drill down in the json output
```
curl http://frontend:8080/status/upstreams/backend/3/state
```
* Clean up the containers
```
./clean-containers.sh
```
* Reload the load balancer
```
service nginx reload
```

# Some command line things:

```
./upstream_conf.sh
```
Explicitly add containers to the load balancer

## List your IP addresses
```
# eth0 interface
ip addr show eth0 | grep "inet " | awk '{print $2}' | sed 's@/.*@@'

# eth1 interface
ip addr show eth1 | grep "inet " | awk '{print $2}' | sed 's@/.*@@'
```
## Generate random files
```
echo '#random { background: rgb(' $(( (RANDOM % 255) )) ',' $(( (RANDOM % 255) )) ',' $(( (RANDOM % 255) )) '); }'
```
## Build container
```
docker build -t random-nginx-demo .
```
## Run a sample container
```
docker run -p 9085:80 -d random-nginx-demo
```

