# Demo to show creating an NGINX Plus environment in Docker and auto-scaling upstream groups

This demo uses one NGINX Plus instance as a load balancer with two upstream groups, one for NGINX Plus web servers and one for NGINX Unit servers.  All of the instances run in Docker containers.

The demo uses the NGINX Plus API to extract metrics and add and remove backend NGINX web servers.  If shows creating a new NGINX Plus environment and adding and removing containers manually and with autoscaling.

## System requirements and setup

The demo runs on a single Docker host.  It has been tested with NGINX Plus R15+, NGINX Unit 1.7, Ubuntu 16.04+, CentOS 7.6, Docker 17.12.0-ce and siege 3.0.8 for generating load.

The base NGINX Plus Docker image, *nginxplus*, exposes ports 80 and 443.  The NGINX Plus load balancer image, *nginxpluslb* also exposes ports 8080 for the NGINX Plus API and 9080 for the NGINX Unit upstream servers.  For the NGINX Plus web server instances, we want to copy the html files to each container because they contain two versions of a health check page, one with an OK message and one with an error message and we want to be able to change the files on each container independently, so another Docker image, *nginxplusws* is created.

For its configuration file, the NGINX Plus load balancing container links ```/etc/nginx/conf.d``` in the container to a directory on the Docker host, ```NGINX-Demos/autoscaling-demo/nginx_config```.

The NGINX Plus web server containers use a default configuration have the content directory in the Docker context for that container copied to ```/usr/share/nginx/html```.

The NGINX Unit servers use a configuration and content stored in ```/srv/app/app.config``` with one program, ```hello.php```.

### Initial setup

To install the demo (assuming the default directories), follow these steps: 

1. If the Python *requests* module is not installed:<br>
   &nbsp;&nbsp;&nbsp;&nbsp;If pip is not installed:<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```wget https://bootstrap.pypa.io/get-pip.py```<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```python get-pip.py```<br>
   &nbsp;&nbsp;&nbsp;&nbsp;```pip install requests```
2. Extract the files from Github: ```git clone https://github.com/nginxinc/NGINX-Demos```
3. Copy ```nginx-repo.crt``` and ```nginx-repo.key``` to ```nginx_base```
4. Create the base NGINX Plus image: ```$ ./root/NGINX-Demos/autoscaling-demo/nginx_base/createbaseimage.sh```<br>
5. Create the load balancer NGINX Plus image: ```$ ./root/NGINX-Demos/autoscaling-demo/nginx_lb/createlbimages.sh```
6. Create the web server NGINX Plus image: ```$ ./root/NGINX-Demos/autoscaling-demo/nginx_ws/createwsimages.sh```
7. Create the NGINX Unit image: ```$ ./root/NGINX-Demos/autoscaling-demo/unit/createunitimage.sh```
8. Note: If the system firewall (ufw on Ubuntu or firewalld on CentOS) is enabled, the default settings will cause networking issues.  Disable it or open the necessary ports.

## Shell Scripts and Programs

The following scripts are available in ```NGINX-Demos/autoscaling-demo/scripts```.<br>
       
Please note that these scripts will need to be executed with root privileges. If you do not have root privileges, you will see the following somewhat cryptic error below:

```Cannot connect to the Docker daemon. Is the docker daemon running on this host?```

* **addnginxlb.sh**: Creates one NGINX Plus load balancing container.

* **addnginxws.sh**: Creates one or more NGINX Plus web server containers and adds them to the *nginx_backends* upstream group.  There is one optional input parameter, the number of containers to create, which defaults to one. Calls ```addnode.sh```.

	usage: ```./addnginxws.sh [number of containers]```

* **addnode.sh**: Called by ```addnginxws.sh``` and ```addunit.sh``` which pass in the information necessary to create a container and add it to an upstream group.

* **addnodes.sh**: Called by ```autoscale.py``` which passes in the information necessary to create one or more containers and add them to an upstream group.

* **addunit.sh**: Creates one or more NGINX Unit container and adds them to the *unit_backends* upstream group.  There is one optional input parameter, the number of containers to create, which defaults to one.  Calls ```addnode.sh```.

	usage: ```./addunit.sh [number of containers]```
	
* **autoscale.py**: Demonstrates auto scaling of NGINX Plus web server containers.  This Python program utilizes the NGINX Plus API to scale NGINX web server containers up and scale down , adding and removing them from the upstream group based on the request rate per node.  A set of default values are defined in the program that are used to control the autoscaling behavior. These define the minimum number of nodes, the maximum number of nodes, the maximum number of nodes to scale up at one time and the maximum number of nodes to scale down at one time.  They also control the number of requests per second per node at which to scale down and the requests per second per node at which to scale up.  The calculations are based off of the number of active/up nodes.  These values can be modified using command line flags.

```
usage: autoscale.py [-h] [-v] [--NGINX_API_URL NGINX_API_URL]
                    [--nginx_server_zone NGINX_SERVER_ZONE]
                    [--nginx_upstream_group NGINX_UPSTREAM_GROUP]
                    [--nginx_upstream_port NGINX_UPSTREAM_PORT]
                    [--docker_image DOCKER_IMAGE]

                    [--sleep_interval SLEEP_INTERVAL] [--min_nodes MIN_NODES]
                    [--max_nodes MAX_NODES]
                    [--max_nodes_to_add MAX_NODES_TO_ADD]
                    [--max_nodes_to_remove MAX_NODES_TO_REMOVE]
                    [--min_rps MIN_RPS] [--max_rps MAX_RPS]

	optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         Provide more detailed output
  --NGINX_API_URL NGINX_API_URL
                        URL for NGINX Plus Status API
  --nginx_server_zone NGINX_SERVER_ZONE
                        The NGINX Plus server zone to collect requests count
                        from
  --nginx_upstream_group NGINX_UPSTREAM_GROUP
                        The NGINX Plus upstream group to scale
  --nginx_upstream_port NGINX_UPSTREAM_PORT
                        The port for the upstream servers to listen on
  --docker_image DOCKER_IMAGE
                        The Docker image to use when createing a container                      

  --sleep_interval SLEEP_INTERVAL
                        The sleep interval between checking the status
  --min_nodes MIN_NODES
                        The minimum healthy nodes to keep in the upstream
                        group
  --max_nodes MAX_NODES
                        The maximum nodes to keep in the upstream group,
                        healthy or unhealthy
  --max_nodes_to_add MAX_NODES_TO_ADD
                        The maximum nodes to add at one time
  --max_nodes_to_remove MAX_NODES_TO_REMOVE
                        The maximum nodes to remove at one time
  --min_rps MIN_RPS     The rps per node below which to scale down
  --max_rps MAX_RPS     The rps per node above which to scale up
```
  
* **createenv.sh**: Creates an environment with one NGINX Plus container for load balancing, one NGINX Plus container for web serving and one NGINX Unit container.  Runs the scripts ```addnginxlb.sh```, ```addnginxws.sh``` and ```addunit.sh```.

* **fixerror.sh**: Copies ```healthcheck.html.ok``` to ```healthcheck.html``` in the NGINX Plus web server container so that the health check will succeed.  There is one required input parameter, the container port mapped to 80.  

	usage: ```./fixerror.sh [port]```

* **persistoff.sh**: Disableds session persistence for the NGINX web server backends.  This is done by copying the file ```nginx_config/demo.conf.nosp``` to ```nginx_config/dem.conf``` and sending a signal to the NGINX Plus container to reload the configuration. Note: the default ```demo.conf``` file has session persistence disabled.

* **persiston.sh**: Enables session persistence for the NGINX web server backends.  This is done by copying the file ```nginx_config/demo.conf.sp``` to ```nginx_config/demo.conf``` and sending a signal to the NGINX Plus container to reload the configuration.

* **removebackends.sh**: Deletes all the NGINX Plus web server containers and NGINX Unit containers from the upstream groups and removes the containers.  The NGINX Plus load balancing container remains running.

* **removecontainers.sh**: Removes all the NGINX Plus and NGINX Unit containers.

* **removenginxws.sh**: Deletes one or more NGINX Plus web server containers from the *nginx_backends* upstream group and removes the containers.

    usage: ```./removenginxws.sh [number of containers]```

* **removenode.sh**: Called by ```removenginxws.sh``` and ```removeunit.sh``` which pass in the information necessary to delete a container and remove it from an upstream group.

* **removenodes.sh**: Called by ```autoscale.py``` which passes in the information necessary to delete one or more containers and remove them from an upstream group.

* **removeunit.sh**: Deletes one or more NGINX Unit containers from the *unit_backends* upstream group and removes the containers.

    usage: ```./removeunit.sh [number of containers]```
    
* **runsiegefixed.sh**: Runs the siege load generation tool for a fixed duration and number of connections.  It makes requests to: ```http://<docker host ip address>/index.html``` 

* **runsiege.sh**: Runs the siege load generation tool.  It runs an infinite loop and for each iteration it randomly choses the duration and the number of connections to run.  It makes requests to: ```http://<docker host ip address>/index.html```

* **seterror.sh**: Copies ```healthcheck.html.err``` to ```healthcheck.html``` in the NGINX Plus web server container so that the health check will fail.  There is one required input parameter, the container port mapped to 80.  

	usage: ```./seterror.sh [port]```

## Other Files and Directories

The following additional files are used:

* **nginx_base/Dockerfile:** The Dockerfile to create the base NGINX Plus image.  It requires that nginx-repo.crt and nginx-repo.key be copied to the ```NGINX-Demos/nginx_base```.  The image will be named *nginxplus*.

* **nginx_conf/demo.conf:** The NGINX Plus load balancing configuration.

* **nginx_conf/demo.conf.nosp:** The NGINX Plus load balancing configuration without session persistence enabled. This is the same as the demo.conf file.
 
* **nginx_conf/demo.conf.sp:** The NGINX Plus load balancing configuration with session persistence enabled for the NGINX Plus web server backends.

* **nginx_lb/Dockerfile:** The Dockerfile to create the NGINX Plus load balancer image, exposing ports 8080 and 9080.  The image will be named *nginxpluslb*.

* **nginx_ws/Dockerfile:** The Dockerfile to create the NGINX Plus web server image, copying the content directory to ```/usr/share/nginx/html``` in the container.  The image will be named *nginxplusws*.

* **scripts/dockerip:** Extracts the IP address of the Docker host.  This file is included in some of the shell scripts.

* **unit/app.config:** The NGINX Unit configuration

* **unit/content/hello.php:** A sample PHP program.

* **unit/Dockerfile:** The Dockerfile to create the NGINX Unit image, exposing ports 8443 and 9080.  The image will be named *nginxunit*.

* **unit/start.sh:** The startup script used for the NGINX Unit Docker image,
       
# Demo Script

All scripts are in the ```scripts``` directory.

1.	If the demo as been run previously, cleanup all the containers: <br>``` $ ./removecontainers.sh```
2.	Show that there are no containers running:<br>```$ docker ps```
3.	In a browser show:<br>```http://[docker host ip address]:8080/dashboard.html```<br>
There will be an error in the browser because NGINX PLUS is not yet running.  Continue to show dashboard.html after each action that effects the NGINX Plus configuration.
4.	Setup the environment:<br>```$ ./createenv.sh```<br>This will create one NGINX PLUS load balancer container, one NGINX PLUS web server container and upstream server and one NGINX Unit container and upstream server. 
5.	Show that there are now containers running:<br>```$ docker ps```
6.	Create some more NGINX Unit containers:<br>```$ ./addunit [number of containers]```
7.	Remove some NGINX Unit containers:<br>```$ ./removunit [number of containers]```
8.	Create some more NGINX Plus web server containers:<br>```$ ./addnginxws [number of containers]```
9.	Remove some NGINX Plus web server containers:<br>```$ ./removnginxws [number of containers]```
10.	In a browser show:<br>```http://[docker host ip address]```<br>And see that requests are load balanced across the NGINX Plus web server backends.
11.	Enable session persistence:<br>```$ ./persiston.sh```
12.	In a browser show:<br>```http://[docker host ip address]```<br>And see that requests are now all sent to a single NGINX Plus web server.
13.	Disable session persistence:<br>```$ ./persistoff.sh```
14.	In a browser show:<br>```http://[docker host ip address]```<br>And see that requests are now being load balanced across the NGINX Plus web server backends again.
15.	Show script ```createenv.sh```.  This script calls the following three scripts.
16.	Show script ```addnginxlb.sh```.  This script creates a container with NGINX PLUS configured as a load balancer with an upstream group for NGINX PLUS as a web server and another for NGINX Unit.
17.	Show script ```addnginxws.sh```. This script adds a container with NGINX Plus, using the default configuration and adds it as an upstream server.  If copies the html content from the Docker host.
18.	Show script ```addunit.sh```. This script adds a container with NGINX Unit and adds it as an upstream server.
19.	Show script ```addnode.sh```.  This script is called by the previous two scripts and does the actual container creation and upstream server additions.
20.	Show script ```removenginxws.sh```.  This script removes one or more NGINX Plus webserver upstream servers and their containers.
21.	Show ```../nginx_config/docker.conf```
22.	Show ```../nginx_base/Dockerfile```
23.	Show ```../nginx_lb/Dockerfile```
24.	Show ```../nginx_ws/Dockerfile```
25.	Show ```../unit/Dockerfile```
26.	Generate load: <br>```$ ./runsiege.sh```.
27.	Enable auto scaling:<br>```$ ./autoscale.py```<br>This program will try and keep the requests per second per active node to between 10 and 12.  It will add at most 4 nodes on scale up and remove at most 2 nodes on scale down.  It is checking every 2 seconds.  There can be a maximum of 10 total nodes and a minimum of 2 active nodes.
28.	Cause a web server to fail the health check:<br>```$ ./seterror.sh [port]```<br>For one or more NGINX Plus web server instances.  The autoscaling algorithm will do the request rate per node calculation on the backends that are healthy.
29.	Show ```autoscale.py```.
30.	Stop the load generator when there are more then 2 active nodes.  The autoscaling program will scale down to 2 active nodes.
31.	Cause an unhealthy web server to pass the health check:<br>```$ ./fixerror [port]```<br>As nodes return to health, more backends will be removed to maintain the minimum of 2 active nodes.




