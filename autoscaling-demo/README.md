# Demo to show creating an NGINX Plus environment in Docker and auto-scaling upstream groups

This demo uses one NGINX Plus instance as a load balancer with two upstream groups, one for NGINX Plus web servers and one for Elasticsearch nodes.  All of the instances run in Docker containers.

The demo uses both the upstream_conf and status api's.  If shows creating a new NGINX Plus environment and adding and removing containers manually and with autoscaling.

## System requirements and setup

The demo runs on a single Docker host.  It requires NGINX Plus R8+.  It has been tested with Ubuntu 14.04, Docker 1.7.0, 1.8.1 and 1.8.2, ElasticSearch 1.4.4 and  siege 3.0.5 for generating load.

The base NGINX Plus Docker image, nginxplus, is created using ```docker\_base/Dockefile``` which closely matches the Dockerfile from the blog post ```http://nginx.com/blog/deploying-nginx-nginx-plus-docker/```.  This image exposes ports 80 and 443.  For the NGINX Plus load balancer we want to also expose ports 8080 for the status API and 9200 for Elasticsearch.  For this a new image, ```nginxpluslb```, is created using ```docker_lb/Dockerfile``` which is based on the ```nginxplus``` image.  For the NGINX Plus web server instances, we want to copy the html files to each container because they contain two versions of a health check page, one with an OK message and one with an error message and we want to be able to change the files on each container independently, so another Docker image, ```nginxplusws```, is created using ```docker_ws/Dockerfile```.

For its configuration file, the NGINX Plus load balancing container links ```/etc/nginx/conf.d``` in the container to a directory on the Docker host, ```/srv/NGINX-Demos/autoscaling-demo/nginx_config``` by default.

The NGINX Plus web server containers have the content directory in the Docker context for that container copied to ```/usr/share/nginx/html```.

The NGINX Plus web server containers and Elasticsearch containers use default configurations.

## Setup Options:

### Fully automated Vagrant/Ansible setup:

1. Install Vagrant using the necessary package for your OS:

	http://www.vagrantup.com/downloads

1. Install provider for vagrant to use to start VM's.  

	The default provider is VirtualBox [Note that only VirtualBox versions 4.0, 4.1, 4.2, 4.3 are supported], which can be downloaded from the following link:

	https://www.virtualbox.org/wiki/Downloads

	A full list of providers can be found at the following page, if you do not want to use VirtualBox:

	https://docs.vagrantup.com/v2/providers/

1. Install Ansible:

	http://docs.ansible.com/ansible/intro_installation.html

1. Clone demo repo

	```$ git clone git@github.com:nginxinc/NGINX-Demos.git```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```~/NGINX-Demos/autoscaling-demo/ansible/files/```

1. Move into the directory and start the Vagrant vm:

	```
	$ cd ~/NGINX-Demos/autoscaling-demo
	$ vagrant up
	```

1. Login in the newly created virtual machine:

	```
	$ vagrant ssh
	```

The demo files will be in ```/srv/NGINX-Demos/autoscaling-demo/scripts```

### Ansible only deployment

1. Create Ubuntu 14.04 VM

1. Install Ansible and Giton Ubuntu VM

	```
	$ sudo apt-get install ansible git
	```

1. Clone demo repo into ```/srv``` on Ubuntu VM:

	```
	$ cd /srv
	$ sudo git clone git@github.com:nginxinc/NGINX-Demos.git
	```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```/srv/NGINX-Demos/autoscaling-demo/ansible/files/```

1. Run ansible playbook against localhost on Ubuntu VM:

	```
	$ sudo ansible-playbook -i "localhost," -c local /srv/NGINX-Demos/autoscaling-demo/ansible/setup_autoscaling_demo.yml
	```

The demo files will be in ```/srv/NGINX-Demos/autoscaling-demo/scripts```

### Manual Install

The script installautoscale.sh can be used to install the demo.  The script requires the the files ```nginx-repo.crt``` and ```nginx-repo.key``` be copied to ```/etc/ssl/nginx```.  This script has been tested on Ubuntu 14.04.  It will install curl, docker, git and siege if they are not already installed.  The demo files will then be extracted from Github and finally the 3 Docker images will be created as well as the Elasticsearch image.  The script will prompt for the root directory where the files should be extracted to.  The default is ```/root/nginxdemos```. The files will be extracted to the r-autoscaling directory within this root directory.  

To manually install the demo (assuming the default directories), follow these steps: 

1. Extract the files from Github into ```/srv/NGINX-Demos/autoscaling-demo``` 
2. Copy ```nginx-repo.crt``` and ```nginx-repo.key``` to ```/srv/NGINX-Demos/autoscaling-demo/docker_base```
3. Create the base NGINX Plus image
	```
	$ cd to /srv/NGINX-Demos/autoscaling-demo/docker_base
	./createbaseimage.sh
    ```
    This runs the command: ```docker build -t nginxplus .```
4. Create the load balancer NGINX Plus image
	```
	$ cd /srv/NGINX-Demos/autoscaling-demo/docker_lb
	$ ./createlbimages.sh
	```
    This runs the command: ```docker build -t nginxpluslb .```
5. Create the web server NGINX Plus image
	```
	$ cd /srv/NGINX-Demos/autoscaling-demo/docker_ws
	$ ./createwsimages.sh
	```
    This runs the command: ```docker build -t nginxplusws```.
6. Get the Elasticsearch image
	```
	$ docker pull elasticsearch
	```

## Shell Scripts and Programs

The following scripts are available in cd ```/srv/NGINX-Demos/autoscaling-demo/scripts```

Please note these scripts will need to be executed with root privileges. If you do not have root privileges, you will see the following somewhat cryptic error below:

       Cannot connect to the Docker daemon. Is the docker daemon running on this host?

* **addes.sh**: Create one or more Elasticsearch containers and adds them to the upstream group.  There is one optional input parameter, the number of containers to create, which defaults to one.  Calls ```addnode.sh```.

	usage: ```./addes.sh [number of containers]```

* **addnginxlb.sh**: Create one NGINX Plus load balancing container.

* **addnginxws.sh**: Create one or more NGINX Plus web server containers and adds them to the upstream group.  There is one optional input parameter, the number of containers to create, which defaults to one. Calls ```addnode.sh```.

	usage: ```./addnginxwsmulti.sh [number of containers]```

* **addnode.sh**: Called by ```addes.sh``` and ```addnginxws.sh``` which pass in the information necessary to create a container and add it to an upstream group.

* **autoscale.py**: Demonstrates auto scaling of NGINX Plus web server containers.  This Python program utilizes the NGINX Plus status and configuration API's to scale up and scale down NGINX web server containers, adding and removing them from the upstream group based on the request rate per node.  A set of variables defined at the top of the program are used to control the autoscaling behavior. This control the minimum number of nodes, the maximum number of nodes, the maximum number of nodes to scale up at one time and the maximum number of nodes to scale down at one time.  They also control the number of requests per second per node at which to scale down and the requests per second per node at which to scale up.  It bases its calculations off of the number of active/up nodes.

* **createenv.sh**: Creates an environment with one NGINX Plus container for load balancing, one NGINX Plus container for web serving and one Elasticsearch container.  Runs the scripts ```addnginxlb.sh```, ```addnginxws.sh``` and ```addes.sh```.

* **fixerror.sh**: Copies ```healthcheck.html.ok``` to ```healthcheck.html``` in the nginx web server container so that the health check will succeed.  There is one required input parameter, the port mapped to 80.  

	usage: ```./fixerror.sh [port]```

* **persistoff.sh**: Disableds session persistence for the NGINX web server backends.  This is done by copying the file ```nginx_config/docker.conf.nosp``` to ```nginx_config/docker.conf``` and sending a signal to the NGINX Plus container to reload the configuration. Note: the default ```docker.conf``` file has session persistence disabled.

* **persiston.sh**: Enables session persistence for the NGINX web server backends.  This is done by copying the file ```nginx_config/docker.conf.sp``` to ```nginx_config/docker.conf``` and sending a signal to the NGINX Plus container to reload the configuration.

* **removebackends.sh**: Deletes all the NGINX Plus web server containers and Elasticsearch containers from the upstream groups and removes the containers.  The NGINX Plus load balancing container remains running.

* **removecontainers.sh**: Removes all the NGINX Plus and Elasticsearch containers.

* **removees.sh**: Deletes one or more Elasticsearch containers from the upstream group and removes the containers.

    usage: ```./removees.sh [number of containers]```

* **removenginxws.sh**: Deletes one or more NGINX Plus web server containers from the upstream group and removes the containers.

    usage: ```./removenginxws.sh [number of containers]```

* **removenode.sh**: Called by ```removees.sh``` and ```removenginxws.sh``` which pass in the information necessary to delete a container and remove it from an upstream group.

* **runsiegefixed.sh**: Runs the siege load generation tool for a fixed duration and number of connections.  It makes requests to: ```http://docker/index.html``` 

* **runsiege.sh**: Runs the siege load generation tool.  It runs an infinite loop and for each iteration it randomly choses the duration and the number of connections to run.  It makes requests to: ```http://docker/index.html```

* **seterror.sh**: Copies ```healthcheck.html.err``` to ```healthcheck.html``` in the nginx web server container so that the health check will fail.  There is one required input parameter, the port mapped to 80.  

	usage: ```./seterror.sh [port]```

## Other Files and Directories

The following additional files are used:

* <b>nginx\_conf/docker.conf:</b> This contains the NGINX Plus load balancing configuration.

* <b>nginx\_conf/docker.conf.nosp:</b> This contains a NGINX Plus load balancing configuration without session persistence enabled. This is the same as the docker.conf file.
 
* <b>nginx\_conf/docker.conf.sp:</b> This contains a NGINX Plus load balancing configuration with session persistence enabled for the NGINX web server backends.

* <b>docker_base/Dockerfile:</b> This is the Dockerfile to create the base NGINX Plus image.  It requires that nginx-repo.crt and nginx-repo.key be copied to the Docker context (the directory where the Dockerfile lives).  The image should be named <i>nginxplus</i>.

* <b>docker_lb/Dockerfile:</b> This is the Dockerfile to create the NGINX Plus image to be used for the load balancer, exposing ports 8080 and 9200.

* <b>docker_ws/Dockerfile:</b> This is the Dockerfile to create the NGINX Plus image to be used for the web server, copying the content directory to ```/usr/share/nginx/html``` in the container.

* <b>scripts/dockerip:</b> Extracts the IP address of the Docker host.  This is included in some of the shell scripts.

* <b>autoscaling\_demo_script.docx:</b> The demo script, also shown below.

# Demo Script

All scripts are in the ```scripts``` directory.
1.	If the demo as been run previously, cleanup all the containers: <br>``` $ ./removecontainers.sh```1.	Show that there are no containers running:<br>```$ docker ps```1.	In a browser show:<br>```http://[docker host]:8080/status.html```<br>
There will be an error in the browser because NGINX PLUS is not yet running.  Continue to show status.html after each action that effects the NGINX Plus configuration.1.	Setup the environment:<br>```$ ./createenv.sh```<br>This will create 1 NGINX PLUS load balancer container, 1 NGINX PLUS web server container 1 upstream server and 1 Elasticsearch container and upstream server. 1.	Show that there are now containers running:<br>```$ docker ps```1.	Create some more Elasticsearch containers:<br>```$ ./addes [number of containers]```1.	Remove some Elasticsearch containers:<br>```$ ./removes [number of containers]```1.	Create some more NGINX web server containers:<br>```$ ./addnginxws [number of containers]```1.	Remove some NGINX web server containers:<br>```$ ./removnginxws [number of containers]```1.	In a browser show:<br>```http://[Docker Host]```<br>And see that requests are load balanced across the NGINX web server backends.1.	Enable session persistence:<br>```$ ./persiston.sh```1.	In a browser show:<br>```http://[Docker Host]```<br>And see that requests are now all sent to a single NGINX web server.1.	Disable session persistence:<br>```$ ./persistoff.sh```1.	In a browser show:<br>```http://[Docker Host]```<br>And see that requests are now being load balanced across the NGINX web server backends again.1.	Show script ```createenv.sh```.  This script calls the following 3 scripts.1.	Show script ```addnginxlb.sh```.  This script creates a container with NGINX PLUS configured as a load balancer with an upstream for NGINX PLUS as a web server and one for Elasticsearch.1.	Show script ```addnginxws.sh```. This script adds a container with NGINX Plus, using the default configuration and adds it as an upstream server.  If copies the html content from the Docker host.1.	Show script ```addes.sh```. This script adds a container with Elasticsearch and adds it as an upstream server.1.	Show script ```addnode.sh```.  This script is called by the previous 2 scripts and does the actual container creation and upstream server additions.1.	Show script ```removenginxws.sh```.  This script removes 1 or more NGINX Plus nodes and their containers.
1.	Show ```../nginx_config/docker.conf```.1.	Show ```../docker_base/Dockerfile```.1.	Show ```../docker_lb/Dockerfile```.1.	Show ```../docker_ws/Dockerfile```.1.	Generate load: <br>```$ ./runsiege.sh```.1.	Enable auto scaling:<br>```$ ./autoscale.py```<br>This program will try and keep the requests per second per active node to between 10 and 12.  It will add at most 4 nodes on scale up and remove at most 2 nodes on scale down.  It is checking every 2 seconds.  There can be a maximum of 10 total nodes and a minimum of 2 active nodes.1.	Cause a web server to fail the health check:<br>```$ ./seterror.sh [port]```<br>For one or more NGINX Plus web server instances.  The autoscaling algorithm will do the request rate per node calculation on the backends that are healthy.1.	Show ```autoscale.py```.1.	Stop the load generator when there are more then 2 active nodes.  The autoscaling program will scale down to 2 active nodes.1.	Cause a unhealthy web server to pass the health check:<br>```$ ./fixerror [port]```<br>As nodes return to health, more backends will be removed to maintain the minimum of 2 active nodes.