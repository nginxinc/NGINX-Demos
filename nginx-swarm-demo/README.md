# Load balancing in Docker Swarm (Docker 1.12) with NGINX F/OSS and NGINX Plus with autoscaling

## Overview

This demo was shown as part of the 2016 NGINX conference session: *Load Balancing Containers in a Docker Swarm Cluster with NGINX and NGINX Plus*.

#### The demo includes three sections:

* Docker Swarm load balancing to a simple web app backend.

* Docker Swarm with NGINX F/OSS for SSL offload. Load balancing by the Swarm load balancer to the same simple web app backend.

* Docker Swarm with NGINX Plus for SSL offload, NGINX Plus behind the Swarm load balancer doing the load balancing to two NGINX/PHP-FPM services.  With autoscaling.

The demo uses the Docker Service API and NGINX Plus Status API.  It shows creating Docker services and load balancing those services with the Docker Swarm load balancer and with NGINX Plus.  It shows scaling those services both manually with the Docker CLI and automatically using the Docker CLI and Service API.

## System Requirements and Setup

The following is assumed:  

* The user will be logged in as root.  If the commands are to be run by a non-root user, then many commands will need to prefixed with sudo.
* The demo files will be installed at `/root/NGINX-Demos/nginx-swarm-demo/`
* All Docker images will be built on the Swarm master and pushed to a private DockerHub repo.  If the Docker images are to be built localy on the worker nodes, then the steps required are noted.
* All commands used during the demo will be executed on the master node, even those that don't have to be run from the master node.  

The demo runs on a Swarm cluster of three Docker hosts; a master and two workers.  It requires NGINX Plus R8+.  It has been tested with NGINX Plus R10 and R11, Ubuntu 16.04, Docker 1.12.1, 1.12.3-rc1, 17.4.0 and 17.5.0, etcd 3.0.6 siege 3.0.8 and Python 2.7.12.  It assumes that the following software packages are installed:

* openssh-client and openssh-server  
* curl   
* git
* vim

A DockerHub account is required if the Docker images are to be pushed and pulled from a DockerHub repo.

In the base directory for the demo files there is a directory matching the name of each image.  This directory contains the Docker file and any other files used by that image. All files used by an image are copied to the image.

This demo requires NGINX Plus, therefore you must have valid nginx-repo.crt and nginx-repo.key files to access the NGINX Plus repository and copy them to the appropriate directory as specified below.

To allow the demo commands to be scripted, `demo-magic.sh` from <https://github.com/paxtonhare/demo-magic> is used.

### Initial setup:

The following instructions are for Ubuntu 16.04 but can be adapted to other operating systems supported by [NGINX Plus](https://www.nginx.com/products/technical-specs/).  

*On each node in the Swarm cluster:*

**Install Docker:**

`curl -fsSL https://get.docker.com/ | sh`

**Allow Docker to be used by a non-root user:**

If you will be using Docker with a non-root user:

`usermod -aG docker USER`

**Get the project files:**

`git clone https://github.com/nginxinc/NGINX-Demos`  

**Add the scripts directory to the path:**

Assuming the scripts are in `/root/NGINX-Demos/nginx-swarm-demo/scripts` add the following line to `~/.profile`:

`PATH=$PATH:/root/NGINX-Demos/nginx-swarm-demo/scripts`

Log out and back in again to have it take effect.

**Install Python** - Used by autoscale.py

```
apt-get install python2.7 python2.7-dev
ln -s /usr/bin/python2.7 /usr/bin/python
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
```

**Install PHP HTTP client** - Used by service1.php

Download `http://phphttpclient.com/downloads/httpful.phar` to the service1/content directory.

`wget -nv -O /root/NGINX-Demos/nginx-swarm-demo/service1/content/httpful.phar http://phphttpclient.com/downloads/httpful.phar`

*On the Swarm master:*

**Create a swarm:**

`docker swarm init --advertise-addr SWARM_MASTER_IP_ADDRESS`

For example:

`docker swarm init --advertise-addr 192.168.187.128`

*On the Swarm workers:*

**Add a worker to the swarm:**

The required command will be output as part of the previous command.

`docker swarm join --token TOKEN SWARM_MASTER_IP_ADDRESS:2377`

For example:

`docker swarm join --token SWMTKN-1-4xsxokbg0k2uln65gqcgkt8pe9sf32tpcqn4uljb7ys9u78jwu-88yh9u2nxmlo2igrcjt1jx3vh 192.168.187.128:2377`

*On the Swarm master:*

**Set the Swarm master host name**

The host name for the Swarm master used in the demo is defined in `/NGINX-Demos/nginx-swarm-demo/scripts/constants.inc` and defaults to `swarmmaster`.  If a different value is to be used, edit this file.

There must also be an entry in the `/etc/hosts` file for the Swarm master host name.

**Install Docker Python Client** - Used by autoscale.py

`pip install docker-py`

**Install pv** - Used for the demo script

`apt-get install pv`

**Install demo-magic.sh** - Used by the demo script

Download `https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh ` to the scripts directory.

`wget -nv -O /root/NGINX-Demos/nginx-swarm-demo/scripts/demo-magic.sh https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh `

**Install Siege**

`apt-get install siege`

**Install vim** (If not already installed)

`apt-get install vim`

**Install NGINX syntax highlighting**

```
wget http://hg.nginx.org/nginx/archive/f38043bd15f5.tar.gz
tar xvf f38043bd15f5.tar.gz
cp -r nginx-f38043bd15f5/contrib/vim /root/.vim
```

Add the falling line to `/root/.vim/ftdetect/nginx.vim`:

`au BufRead,BufNewFile *.conf set ft=nginx`

On the worker nodes:

**Copy the cert and key keys:**

Copy `nginx-repo.crt` and `nginx-repo.key` to `/NGINX-Demos/nginx-swarm-demo/nginxplus`

If the Docker images are being built on each node then also do this on the worker nodes.

*On all nodes:*
 
**Setup the DockerHub repository:**

As previously noted, it is assumed that the images will be built on the master node and pushed to a private DockerHub repository and pulled by the worker nodes.  The DokerHub account and repository is defined by the `dockerPrefix` value in `/show-demos/r-docker-swarm-mode/scripts/constants.inc`.

Edit this file on the master and worker nodes and set `dockerPrefix` to the DockerHub account and repo.  All the images with then be pushed to a single repo, with the tag being the image name.

For example, if the DockerHub user is *mydockerhub* and the repo is named *swarmdemo* (note the ":" at the end):   

`dockerPrefix="mydockerhub/swarmdemo:"`

All the images will be pushed to the *swarmdemo* repo and image tagged with the image name.

**NOTE:** The NGINX Plus image, because it is commercial software, must be pushed to a private repo.  To make sure that NGINX Plus is pushed to a private repo, manually create the repo before pushing any images.

If the Docker images are being built on each node then `dockerPrefix` should be left blank.

*On the Swarm master:*

**Create the Docker images:**

`buildallimages.sh`

This runs scripts in the `etcd`, `hello`, `nginxbasic`, `nginxplus`, `phpfpmbase`, `service1` and `service2` directories to build the docker images.

If the Docker images are being built on each node then also do this on the worker nodes.

Make sure that the *etcd*, *hello*, *nginxbasic*, *nginxplus*, *phpfpmbase*, *service1* and *service2* images were built, using the `docker images` command.  If the *nginxplus* image has not been built, check that the `nginx-repo.crt` and `nginx-repo.key` files have been copied to `/show-demos/r-docker-swarm-mode/nginxplus`. 

**Push the Docker images:**

```
docker login
pushallimages.sh
```

This will push all the images to the DockerHub account specified in `/NGINX-Demos/nginx-swarm-demo/scripts/constants.inc`.

**Pull the Docker images**

Optionaly, you pull the Docker images to each work node prior to running the demo.  This will avoid the delay caused by images being pulled the first time the demo is run.  

```
docker login
pullallimages.sh
```

If the Docker images are being built locally on the worker nodes, this is not necessary.

## Running the Demo

All the scripts and programs used for the demo are in `/NGINX-Demos/nginx-swarm-demo/scripts`.  Most of the commands for the scripted demo are included in `demo-script.sh` which will type them automatically, but some commands must be run in seperate terminal windows. The demo requires five terminal windows logged into the Swarm master.

### Demo cleanup

It is recommended that once the demo is run, that the Docker services and network be removed and all the nodes be rebooted before running the demo again.  
* `removeservices.sh` will remove all services.  
* `removenetwork.sh` will remove the overlay network.  
* `removecontainers.sh` will remove any are containers remaining after the services are removed.  This can be run on each node.

The nodes should then be rebooted.

### Demo process

The five terminal windows will be used for the following:

1. Running the demo script:  This is done by running `demo-script.sh`.  Pressing the space bar or the return key will cause the next command to be typed out.  Pressing the space bar or return key again will cause the command to be executed.
2. Generating load:  This is done by running `runsiege.sh`.  
3. Autoscaling service1:  This is done by running `autoscale.py`
4. autoscaling service 2:  This is done by running `autoscale.py -s service1`

### Demo script

All commands, except those denoted with *Shell* or *Browser* are included in demo-script.sh and will executed through that script.  Those marked with *Shell* need to be run manually in a seperate shell  and those marked with *Browser* should be run from a browser.  This scripts assumes that the host name of the swarmmaster is `swarmmaster`.  demo-script.sh gets the actual host name from `constants.inc`.

If you are executing all the commands below manually, make sure to replace `dockerPrefix` with the DockerHub account and repo. For example, if the DockerHub user is *mydockerhub* and the repo is named *swarmdemo*, then `dockerPrefix="mydockerhub/swarmdemo:"` (note the ":" at the end).

#### Swarm Only Demo

1.  Show Swarm Cluster  
	`# docker node ls`

2.  Create the backend service  
	`# docker service create --name backend-app-swarm -p8085:80 --replicas 3 ${dockerPrefix}hello`

3.  Show the services  
	`# docker service ls`

4.  Show the tasks  
	`# docker service ps backend-app-swarm`

5.  Show a container  
	`# docker ps`

6.  Scale the service  
	`# docker service scale backend-app-swarm=5`

7.  Show that the service scaled  
	`# docker service ps backend-app-swarm`

8.  Show load balancing 1  
	`# curl http://swarmdemo:8085 | grep address`

9.  Show load balancing 2  
	`# curl http://swarmdemo:8085 | grep address`

10.  Show load balancing 3  
	`# curl http://swarmdemo:8085 | grep address`

11.  Show load balancing 4  
	`# curl http://swarmdemo:8085 | grep address`

12.  Show load balancing 5  
	`# curl http://swarmdemo:8085 | grep address`

13.  Delete the backend service  
	`# docker service rm backend-app-swarm`

14. Show the services  
	`# docker service ls`

#### NGINX F/OSS Demo

1. Create the overlay network  
	`# docker network create -d overlay appnetwork`

2. Show the network list  
	`# docker network ls`

3. Create the backend service  
	`# docker service create --name backend-app --replicas 3 –network appnetwork ${dockerPrefix}hello`

4. Create the NGINX F/OSS service  
	`# docker service create --name nginx --replicas 1 -p 8090:80 –p 9443:443 --network appnetwork ${dockerPrefix}nginxbasic`

5. Show the services  
	`# docker service ls`

6. Show the tasks  
	`# docker service ps backend-app`
	
7. Show HTTP load balancing 1  
	`# curl http://swarmdemo:8090 | grep address`

8. Show HTTP load balancing 2  
	`# curl http://swarmdemo:8090 | grep address`
	
9. Show HTTP load balancing 3  
	`# curl http://swarmdemo:8090 | grep address`

10. Show HTTPS load balancing 1  
	`# curl -k https://swarmdemo:9443 | grep address`
	
11. Show HTTPS load balancing 2  
	`# curl -k https://swarmdemo:9443 | grep address`
	
12. Show HTTPS load balancing 3   
	`# curl -k https://swarmdemo:9443 | grep address`  
			
13. Show the nginx configuration  
	`# vim ../nginxbasic/backend.conf`

14. Scale the service  
	`# docker service scale backend-app=5`

15. Show that the service scaled  
	`# docker service ps backend-app`

16. Show HTTPS load balancing 1  
	`# curl -k https://swarmdemo:9443 | grep address`

17. Show HTTPS load balancing 2  
	`# curl -k https://swarmdemo:9443 | grep address`

18. Show HTTPS load balancing 3  
	`# curl -k https://swarmdemo:9443 | grep address`

19. Show HTTPS load balancing 4  
	`# curl -k https://swarmdemo:9443 | grep address`

20. Show HTTPS load balancing 5  
	`# curl -k https://swarmdemo:9443 | grep address`

21. Remove the services  
	`# docker service rm nginx backend-app`

22. Remove the overlay network  
	`# docker network rm appnetwork`

#### NGINX Plus Demo Part 1

1. Create the overlay network  
	`# docker network create -d overlay appnetwork`

2. Create the service1 service  
	`# docker service create --endpoint-mode dnsrr --name service1 --replicas 3 --network appnetwork ${dockerPrefix}service1`

3. Create the service2 service  
	`# docker service create --endpoint-mode dnsrr --name service2 --replicas 3 --network appnetwork ${dockerPrefix}service2`

4. Create the etcd service  
	`# docker service create --endpoint-mode dnsrr --name etcd --network appnetwork --replicas 1 ${dockerPrefix}etcd`

5. Create the NGINX Plus service  
	`# docker service create --name nginxplus --replicas 1 -p 8080:80 -p8443:443 -p 8081:8081 --network appnetwork ${dockerPrefix}nginxplus`

6. Show the services  
	`# docker service ls`

7. Show the service1 tasks  
	`# docker service ps service1`

8. Show the service2 tasks  
	`# docker service ps service2`

9. Show the etcd tasks  
	`# docker service ps etcd`

10. Show the nginxplus tasks  
	`# docker service ps nginxplus`

11. Show NGINX Plus dashboard  
	Browser: `http://swarmdemo:8081`

12. Show service2  
	Browser: `http://swarmdemo:8080/service2.php`

13. Show service1  
	Browser: `http://swarmdemo:8080/service1.php`

14. Generate load  
	Shell: `# runsiege.sh`

15. Show NGINX Plus dashboard  
	Browser: `http://swarmdemo:8081`

16. Scale the services up  
	`# docker service scale service1=5 service2=5`

17. Show NGINX Plus dashboard  
	Browser: `http://swarmdemo:8081`

18. Show the NGINX Plus configuration  
	`# vim ../nginxplus/backend.conf`

#### NGINX Plus Demo Part 2

1. Run autoscale.py for service1  
	Shell: `# autoscale.py`

2. Run autoscale.py for service2  
	Shell: `# autoscale.py -s service2`

	**Note:** The best setting of the minimum and maximium requests per second to try and maintain is dependent on the systems being used.  The default is a minimum rps of 4 and a maximum of 6.  These values can be changed using the `--min_rps` and `--max_rps` parameters for autoscale.py.   

3. Show NGINX Plus dashboard  
	Browser: `http://swarm demo:8081`

4. Cause a health check to fail  
	Shell: `# seterror.sh CONTAINER_IP_ADDRESS`

5. Fix the health check  
	Shell: `# fixerror.sh CONTAINER_IP_ADDRESS`

## Docker Images

The following Docker images are used for this demo:

* hello: This is based on the nginx image.  There is a simple web page that after some string substitutions by nginx returns the uri, host name and IP address where it is running.  This image is used for the basic Swarm demo (service: backend-app-swarm) and for the NGINX F/OSS demo (service: backend-app).

* nginxbasic: This is based on the nginx image.  This has NGINX F/OSS configured to load balance the backend-app service using the hello image.

* phpfpmbase: This image is based on `dinkel/nginxphpfpm`.  It has a basic PHP-FPM proxy configuration.

* service1: This image is based on `phpfpmbase`.  It has following pages, only the first two of which are used during the demo:
  * service1.php: This page returns the uri, host name and IP address where it is running and it makes a call to service2.php and returns the results. This page includes the file http.phar used to make HTTP requests.
  * healthcheck.php: This call makes a call to etcd using its IP address as the key.  If that key is found, then it returns a status of unhealthly.  If no key is found it returns a status of healthy.
  * These additional pages are also available but not used during the demo:
  		* index.html: This page displays the uri, host name and IP address where it is running.
  		* index.php: This page displays the uri, host name and IP address where it is running.

* service2: This image is based on `phpfpmbase`.  It has following pages, only the first of which is used during the demo:
    * service2.php: This page returns the service name, uri, host name and IP address where it is running, as a JSON response.
    * These additional pages are also available but not used during the demo:
  		* index.html: This page displays the uri, host name and IP address where it is running.
  		* index.php: This page displays the uri, host name and IP address where it is running.

* etcd: This image is based on `quay.io/coreos/etcd`.  This is used for the service1 health check.

* nginxplus: This images is built from scratch.  This has NGINX Plus configured to load balance the two services, service1 and service2.

## Shell Scripts and Programs

The following scripts/programs are available in `NGINX-Demos/nginx-swarm-demo/scripts`.

Please note these scripts and Docker commands will need to be executed with root privileges unless you configured Docker to allow access by a non-root user, per the instruction above. If you try and access the scripts or Docker commands from an unauthorized user you will see the following error:

`Cannot connect to the Docker daemon. Is the docker daemon running on this host?`

The following scripts/programs are required for the scripted demo. Is is assumed they will be run from the Swarm master, but only demo-script.sh must be run from the master.

* **autoscale.py**: Demonstrates auto scaling of NGINX Plus upstream servers running in containers.  This Python program utilizes the NGINX Plus status API and the Docker API to scale up and scale down NGINX backend containers, adding and removing them from the upstream group based on the request rate per node.  A set of parameters can be passed in to control the autoscaling behavior, with all parameters having default values defined. It based its calculation requests per second on the number of active/up nodes.  These are the parameters and their defaults:

	* -h, --help            
  Show this help message and exit
	* -v, --verbose         
  Provide more detailed output.  Default: False
	* --swarm\_master SWARM\_MASTER  
  Host name or IP address of the Swarm Master node.  Default: swarmmaster
	* --docker\_api\_port DOCKER\_API\_PORT  
  HTTP port for the Docker API.  Default: 2375
	* -s SERVICE, --service SERVICE  
  The Swarm service and NGINX Plus upstream group to scale.  Default: service1
	* --nginx\_status\_path NGINX\_STATUS\_PATH  
  URL for NGINX Plus Status API.  Default: status
	* --nginx\_status\_port NGINX\_STATUS\_PORT  
  Port for the NGINX Plus Status API.  Default: 8081
	* --nginx\_server\_zone NGINX\_SERVER\_ZONE  
  The NGINX Plus server zone to collect requests count from.  Default: swarmdemo
	* --sleep\_interval SLEEP\_INTERVAL  
  The sleep interval between checking the status.  Default: 5 seconds
	* --min\_nodes MIN\_NODES  
  The minimum healthy nodes to keep in the upstream group.  Default: 2
	* --max\_nodes MAX\_NODES  
   The maximum nodes to keep in the upstream group, healthy or unhealthy.  Default: 10
	* --max\_nodes\_to\_add MAX\_NODES\_TO\_ADD  
  The maximum nodes to add at one time.  Default: 2
	* --max\_nodes\_to\_remove MAX\_NODES\_TO\_REMOVE  
  The maximum nodes to remove at one time.  Default: 2
	* --min\_rps MIN\_RPS     
  The rps per node below which to scale down.  Default: 4
	* --max\_rps MAX\_RPS     
  The rps per node above which to scale up.  default:6

* **demo-script.sh**: Executes commands for the demo, using demo magic.

* **fixerror.sh**: Causes the health check for a service1 containers to succeed by removing an entry in etd for the IP address of the containers.  There is one required input parameter, the IP address of the container.  This can be run from any node.  

	usage: `fixerror.sh CONTAINER_IP_ADDRESS`

* **runsiege.sh**: Runs the siege load generation tool.  It runs an infinite loop and for each iteration it randomly choses the duration and the number of connections to run.  It makes requests to: `http://SWARM_MASTER_IP/service1.php`

* **seterror.sh**: Causes the health check for a service1 containers to fail by adding an entry in etd for the IP address of the containers.  There is one required input parameter, the IP address of the container.  This can be run from any node.

	usage: `seterror.sh CONTAINER_IP_ADDRESS`

Then following scripts/programs are not required for the scripted demo but contain commands used in the scripted demo or for setting up the environment.  Except where noted, they should be run from the Swarm Master node.

* **buildallimages.sh**: Runs all the image create scripts to create all the necessary Docker images.  This can be run from any node, but if the images are built on the Swarm and pushed to DockerHub this script doesn't need to be run on the worker nodes.

* **constants.inc**: Contains the Swarm master host name and DockerHub repo if any.

* **createbackendendservice.sh**: Creates the backend-app service with 3 containers.

* **createbackendswarmservice.sh**: Creates the backend-app-swarm service with 3 containers.

* **createetcdservice.sh**: Creates the etcd service with 1 containers.

* **createnetwork.sh**: Creates the appnetwork overylay network.

* **createnginxplusservice.sh**: Creates the nginxplus service with 1 container.

* **createservice1.sh**: Creates the service1 service with 3 containers.

* **createservice2.sh**: Creates the service2 service with 3 containers.

* **pullallimages.sh**: Pulls all the Docker images from a DockerHub repo.

* **pushallimages.sh**: Pushes all the Docker images to a DockerHub repo.

* **removecontainers.sh**: Removes all containers.

* **removenetwork.sh**: Removes the appnetwork overylay network.

* **removeservices.sh**: Removes all services.

* **runsiegefixed.sh**: Runs the siege load generation tool for a fixed duration and number of connections.  It makes requests to: `http://SWARM_MASTER_IP/service1.php`

## Other Files and Directories

The following additional files are used:

In the `etcd` directory:

* **createetcimage.sh:** Runs the Docker command to create the etcd image.

* **Dockerfile:** The Docker file to create the etcd image based on the `quay.io/coreos/etcd` image.

In the `hello` directory:

* **createhelloimage.sh:** Runs the Docker command to create the hello image.

* **Dockerfile:** The Dockerfile to create the hello image based on the `nginx` image.

* **hello.conf:** The application NGINX configuration file.  Does string replacements for the uri, host name and IP address in the response.

* **content/index.html:** An HTML page that that has placeholders for uri, host name and IP address to be replaced by NGINX with the actual values.

In the `nginxbasic` directory:

 * **backend.conf:** The application NGINX configuration file.  Proxies to the backend-app containers.  Exposes ports 80 and 443.

* **Dockerfile:** The Docker file to create the nginxbasic image based on the `nginx` image.

* **createnginxbasicimage.sh:** Runs the Docker command to create the nginxbasic image.

* **swarmdemo.crt:** The certificate file for the swarmdemo self-signed certificate.

* **swarmdemo.key:** The key file for the swarmdemo self-signed certificate.

In the `nginxplus` directory:

* **backend.conf:** The application level NGINX configuration file.  Proxies to the service1, service2 and etcd containers.  Has health checks, the status API and upstream_conf API configured.  Exposes ports 80, 443, 2379 and 8081.  It also allows for the healthcheck.php page for specific service1 containers to be displayed at the url `http://SWARM_MASTER_IP/showhealthcheck?ip=IPADDRESS:PORT` where IP_ADDRESS:PORT are the IP address and port of a service1 container.

* **Dockerfile:** The Docker file to create the nginxplusc image by installing NGINX Plus.  Requires that a valid nginx-repo.crt and nginx-repo.key files be copied to this directory.

* **createnginxplusimage.sh:** Runs the Docker command to create the nginxplus image.

* **swarmdemo.crt:** The certificate file for the swarmdemo self-signed certificate.

* **swarmdemo.key:** The key file for the swarmdemo self-signed certificate.

In the `phpfpmbase` directory:

* **createphpfpmimage.sh:** Runs the Docker command to create the PHP-FPM image.

* **Dockerfile:** The Dockerfile to create the PHP-FPM image base on the `dinkel/nginx-phpfpm` image.  Exposes port 80.

* **default.conf:** The main NGINX configuration file.

* **nginx.conf:** An HTML page that that has placeholders for uri, host name and IP address to be replaced by NGINX with the actual values.

* **www.conf:** The PHP-FPM www.conf file.

In the service1 directory:

* **Dockerfile:** The Docker file to create the service1 image based on the phpfpmbase image.

* **createservice1image.sh:** Runs the Docker command to create the service1 image.

* **content/healthcheck.php:** The page that NGINX Plus is configured to access for the service1 active health check.  It makes a requests to etcd using it's IP address as the key.  If it finds an entry they it marks itself as unhealthly.  If no entry is found it marks itself as healthly.

* **content/httpful.phar:** The HTTP request API used to make requests to service2. **REMOVE**

* **content/service1.php:** Returns the uri, host name and IP address of the container and calls service2.php returning the results.

In the service2 directory:

* **Dockerfile:** The Docker file to create the service2 image based on the phpfpmbase image.

* **createservice2image.sh:** Runs the Docker command to create the service2 image.

* **content/service2.php:** Returns the uri, host name and IP address of the container as a JSON response.
leve
