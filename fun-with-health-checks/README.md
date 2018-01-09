# Using Advanced NGINX Plus Active Health Checks with Docker Containers

## Overview

This demo shows examples of how NGINX Plus active health checks can be used with Docker containers, basing the health of a service on resource usage or service usage.  It was part of a presentation at the 2017 NGINX users conference.

#### This demo includes three examples:

* Health checks based on service usage, allowing only one request at a time.  When a request is being processed, the health check returns unhealhy and returns healthy once the request has been completed.

* Health checks based on CPU usage.  The health check returns unhealthy when the CPU usage of a container exceeds a certain threshold.  These containers are not created with a CPU limit.  The health check retrieves the CPU usage for a container as a percentage of the CPU usage for the Docker host, using the Docker API stats.

* Health checks based on memory usage.  The health check returns unhealthy when the memory usage of a container exceeds a certain threshold.  These containers are created with a memory limit of 128M and the health check retrieves the memory usage of a container as a percentage of this limit using the Docker API stats.

The demo uses NGINX Plus as a load balancer and NGINX Unit for the upstream servers.

Consul and Registrator are used for DNS service discovery so that the NGINX Plus Upstream Groups are updated dynamically when containers are scaled.  For more information on using Consul and Registrator with NGINX Plus see: [Consul DNS SRV Demo](https://github.com/nginxinc/NGINX-Demos/tree/master/consul-dns-srv-demo) and [Service Discovery for NGINX Plus Using DNS SRV Records from Consul](https://www.nginx.com/blog/service-discovery-nginx-plus-srv-records-consul-dns/).

The following images are used:

* **NGINX Plus:** This image is created using `nginxplus/Docketfile` which closely matches the Dockerfile from the blog post [Deploying NGINX and NGINX Plus with Docker](http://nginx.com/blog/deploying-nginx-nginx-plus-docker/).  It is named *bhc-nginxplus* and exposes ports 80, 8001, 8002, 8003 and 8082.  A volume is used for the NGINX Plus configuration file, `nginxplus/config/backend.conf`.  The content is copied from `nginxplus/content`.

* **NGINX Unit:**  This image is created using `unit/Docketfile`.  It is named *bhc-unit* and exposes ports 8443 and 9080.  In addition to NGINX Unit, PHP 7.0, Python 2.7, curl and stress (to stress the CPU for the CPU-usage-based health check) are installed.  This image is used for the backend containers that are health checked, with the three types of containers having different web content, attached to the container using a Docker volume.

* **Consul:** This image is used in combination with Registrator for DNS service discovery.  It is named *progrium/consul*.

* **Registrator:** This image is used in combination with Consul for DNS service discovery.  It is named *gliderlabs/registrator*.



## System Requirements and Setup

The demo runs on a single Docker host.  The backend services are written in PHP and Python.  It has been tested with Ubuntu 16.04, NGINX Plus R14, NGINX Unit 0.3, PHP 7.0, Python 2.7, Docker 17.05-ce, 17.06-ce and 17.12-ce and Docker Compose 1.13, 1.14 and 1.18.  The demo uses the `dashboard.html` page and version 2 of the NGINX Plus API, included in NGINX Plus R14.

The following is assumed:

* The user will be logged in as root. If the commands are to be run by a non-root user, many commands will need to be prefixed with `sudo` and a configuration change is required as detailed below.

* The demo files will be installed at `/root/NGINX-Demos/r-fun-with-health-checks`.

* The following have been installed on the Ubuntu server:
	* curl
	* git
	* docker
	* docker-compose

* This demo ultilizes NGINX Plus so you must have valid nginx-repo.crt and nginx-repo.key files copied to the appropriate directory as specified below.

* To allow the demo commands to be scripted, `demo-magic.sh`, from <https://github.com/paxtonhare/demo-magic> is used.

### Initial setup

To install the demo follow these steps:

1. Install Docker if it isn't already installed:<br>`curl -fsSL https://get.docker.com/ | sh`<br>You may need to start the Docker service.

2. Install Docker Compose if it isn't already installed:<br>``curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose``<br>`chmod +x /usr/local/bin/docker-compose`<br>*Note:* To find the latest release, check `https://github.com/docker/compose/releases`.

3. The CPU and memory-usage-based health checks use the Docker API. To configure the API to work with HTTP:
	* Edit `/lib/systemd/system/docker.service` and change the line:<br>`ExecStart=/usr/bin/dockerd -H fd://`<br>to:<br>`ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock`
	* To make the change take effect:<br>`systemctl daemon-reload`<br>`service docker restart`

4. By default, Docker requires commands to be run as root.  If the commands will be run by a non-root user you need to run the following:<br>`usermod -aG docker <USER>`<br> where `<USER>` is the user that will run the commands.

5. Part of this demo specifies a memory limitation for a container.  By default on Ubuntu this will cause an error message when creating a container.  To eliminate this error you must enable memory and swap using GNU GRUB.  Do the following:
	* Edit `/etc/default/grub` and set:<br>`GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"`  
	* Update GRUB: `update-grub`  
	* Reboot the system

6. The demo assumes that there is a host entry, *dockerhost*, for the public IP address of the Docker host.  Create an entry in the `/etc/hosts` file for *dockerhost*.

7. Get the project files:<br>`git clone https://github.com/nginxinc/NGINX-Demos`

8. Copy `nginx-repo.crt` and `nginx-repo.key` to `/root/NGINX-Demos/r-fun-with-health-checks/nginxplus`.

9. Install pv - Used for the demo script<br>`apt-get install pv`

10. Install demo-magic.sh - Used by the demo script<br>Download `https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh`:
`wget -nv -O /root/NGINX-Demos/r-fun-with-health-checks/demo-magic.sh https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh`
Make the script executable:
`chmod a+x demo-magic.sh`

11. Create and pull the required images:<br>`# ./setup_images.sh`<br>This script builds the NGINX Plus and PHP-FPM images and pulls the Consul and Registrator images.

12. The environment variable `HOST_IP` must be exported and set to the IP address of the `docker0` interface:<br>`export HOST_IP=<docker0 IP address>`


## Shell Scripts

The following scripts are available:<br>

* **check_env.sh**: Checks that the environment is properly set up to run the demo.  This script checks that most of the steps required to create the images and run the demo have been completed.  If errors are returned when running `docker-compose up -d`, running `check_env.sh` may reveal the issue.

    usage: `./check_env.sh`

* **demo-script.sh**: Runs a series of commands.  demo-magic is used to type out the commands.

	usage: `./demo-script.sh`

* **remove_containers.sh**: Removes all the containers.

    usage: `./remove_containers.sh`

* **setup_images.sh**: Builds the NGINX Plus image, named *bhc-nginxplus*, and the NGINX Unit image, named *bhc-unit*, and pulls the Consul image, named *progrium/consul*, and the Registrator image, named *gliderlabs/registrator*.  By default it only builds the NGINX Plus and NGINX Unit images if they don't exist.  To force them to be built, use the `-f` flag.

    usage: `./setup_images.sh [-f]`


## Other Files

The following additional files are used:

* **consul_dns_config.json:** This contains the Consul configuration.

* **docker-compose.yml:** This contains the specification of the environment to be created by docker-compose.  Before running `docker-compose up -d`, the NGINX Plus and NGINX Unit images must be created.  This can be done using the `setup_images.sh` script.  The CPU and memory-usage-based health check containers and the Consul container require that the *HOST_IP* environment variable be set to the IP address of the `docker0` interface.

* **nginxplus/Dockerfile:** This is the Docker file for the NGINX Plus image.

* **nginxplus/config/nginx.conf:** This is the base-level NGINX Plus configuration file.

* **nginxplus/config/conf.d/backend.conf:** This is the application-level NGINX Plus configuration file.

* **nginxplus/content/apibusy.html:** This is the HTML page to display when all the upstream servers in an upstream group are unavailable.

* **unit/Dockerfile:** This is the Docker file for the NGINX Unit image.

* **unit/start.sh:** This is the startup script for the NGINX Unit image.

* **unitcnt/app.config:** This is the NGINX Unit configuration.

* **unitcnt/testcnt.py:** This Python program acts as the application and the count-based health check. If it is run with the *healthcheck* query parameter specified, the program acts as the health check. It looks for the existence of the `/tmp/busy` file. If the file is found, the health check will respond as unhealthy and respond as healthy if the file is not found.

	If the *healthcheck* query parameter is not specified, the program acts as the application. It causes the container to appear busy and the health check to fail. The file `/tmp/busy` is created, the program sleeps for the number of seconds specified by the *sleep* query parameter and then the `/tmp/busy` file is removed. If not specified, *sleep* defaults to 10 seconds.

* **unitcpu/app.config:** This is the NGINX Unit configuration.

* **unitcpu/content/hcheck.php:** This PHP program does the CPU-usage-based health check. When CPU metrics are extracted from the Linux command line in the container, they are the metrics for the Docker host, not the individual container.  To get the metrics for a container, the Docker API is used.  With the Docker API, the CPU usage for the container is returned as a percentage of the CPU of the Docker host. For example, if the Docker API shows a CPU usage of 25%, that container is using 25% of the CPU of the Docker host.  The default CPU usage threshold for the demo is 70%.  This can be changed using the `threshold` query parameter, included as part of the `uri` parameter of the `health_check` directive in the NGINX Plus configuration.  The NGINX Plus API is used to determine how many upstream server containers there are and divides the total threshold by the number of containers to get the CPU usage threshold per-container. If the CPU usage for the container exceeds the per container threshold, the health check will respond as unhealthy.

* **unitcpu/content/httpget.inc:** This is used to make HTTP requests.

* **unitcpu/content/testcpu.php:** This PHP program generates CPU usage in the container for the number of seconds specified by the *timeout* query parameter.  If not specified, `timeout` defaults to 10 seconds.  The amount of CPU usage is controlled by the `level` query parameter.  It can have a value of between 1 to 6, with one being the lowest CPU usage.  The default is 4.

* **unitmem/content/hcheck.php:** This PHP program does the memory-usage-based health check. The Docker Stats API is used to check the memory usage for the container, showing a container's usage relative to the individual container. The default memory usage threshold is 70%.  This can be changed using the `threshold` query parameter, included as part of the `uri` paramenter of the `health_check` directive.  If the memory usage for the container is at or above the specified threshold, the health check will respond as unhealthy.

* **/unitmem/content/httpget.inc:** This is used to make HTTP requests.

* **unitmem/conent/testmem.php:** This page generates memory usage in the container. It allocates memory and then sleeps for the number of seconds specified by the `sleep` query parameter. If not specified, `sleep` defaults to 10 seconds.

# Running the Demo

* The commmands used during the demo are scripted in demo-script.sh.  This requires demo-magic as mentioned above.
* Before running the demo for the first time, the required images should be built or pulled with:<br>`setup_images.sh`
* Before each run of the demo, the environment can be checked to make sure that it is set up properly by running the command:<br>`# check_env.sh`
* If the demo has been run previously, all the containers can be removed with:<br>` # ./remove_containers.sh`
* Running the scripted demo requires one browser window and three shell windows.

## Demo Script

All commands, except those marked with "[Browser]" or "[Shell #]" are included in `demo-script.sh` and will be executed through that script.  Those marked with "[Browser]" should be run in a browser and those marked with "[Shell #]" need to be run manually in a seperate shell window.  One of the three shell windows is used to run `demo-script.sh`, and the other two are used for the manually executed commands. Those commands will be labeled as either "[Shell 1]" or "[Shell 2]" to indicate which window they should be run in.

When running `demo-script.sh`, pressing Enter will cause a command to be typed, and pressing Enter again will cause the command to be executed.

Run the demo: `# ./demo-script.sh`

1. Show that there are no containers running:<br>`# docker ps`
2. Set up the environment:<br>`# docker-compose up -d`<br>This will create one NGINX PLUS load balancer container, containers for Consul and Registrator, and one each of the count, CPU and memory-usage-based health check containers that will be added to the three upstream groups using DNS service discovery.
3. Show that there are now containers running:<br>`# docker ps`
4. [Browser] Show the NGINX Plus dashboard:<br>`http://<docker host>:8082/dashboard.html#upstreams`
5. Scale each of the Upstream Groups to have two containers:<br>`# docker-compose up --scale phpcnt=2 --scale phpcpu=2 --scale phpmem=2 -d`
6. [Browser] Show that the dashboard reflects the new containers.
7. Run the count-based health check:<br>`# curl http://localhost:8001/testcnt.py?healthcheck`
8. Run the count-based health check again to see that the requests are being load balanced:<br>`# curl http://localhost:8001/testcnt.py?healthcheck`
9. Run the CPU-usage-based health check:<br>`# curl http://localhost:8002/hcheck.php`
10. Run the memory-usage-based health check:<br>`# curl http://localhost:8003/hcheck.php`
11. [Shell 1] Run the health check for one of the count-based containers using the healthcheck path:<br>`# curl http://localhost/healthcheckpy?server=<Container IP Address:Port>`
12. Make one of the count-based containers busy:<br>`# curl http://localhost:8001/testcnt.py`
13.	[Browser] Show the dashboard to see that the health check fails for one of the count-based containers and wait to see it return to health.
14.	[Shell 1] Run the health check for the busy container to show that it has failed:<br>`# curl http://localhost/healthcheckpy?server=<Container IP Address:Port>`
15. [Shell 1] After the container returns to health run the health check again:<br>`# curl http://localhost/healthcheckpy?server=<Container IP Address:Port>`
16. Make both of the count-based containers busy:<br>`# curl http://localhost:8001/testcnt.py&`<br>`curl http://localhost:8001/testcnt.py`
17. [Browser] Show the dashboard to see that both count-based containers have failed the health check.
18. Show that you see the API busy page if you try the testcnt.py page again:<br>`# curl http://localhost:8001/testcnt.py`
19. Scale down the cpu-usage-based Upstream Group to have one container:<br>`# docker-compose up --scale phpcnt=2 --scale phpcpu=1 --scale phpmem=2 -d`
20. [Shell 2] Run docker stats:<br>`# docker stats`
21. Send a request to one of the CPU-usage-based containers that uses less CPU than the threshold for one container (70%) but more than the threshold for 2 containers (35%):<br>`# curl http://localhost:8002/testcpu.php`
22. [Shell 2] View docker stats to see the CPU usage go up on one of the containers.
23. [Browser] Show the dashboard to see that none of the CPU-usage-based containers have failed the health check.
24. Scale up the cpu-usage-based Upstream Group to have two containers:<br>`# docker-compose up --scale phpcnt=2 --scale phpcpu=2 --scale phpmem=2 -d`
25. Send a request to one of the CPU-usage-based containers that uses more than the threshold for 2 containers (35%):<br>`# curl http://localhost:8002/testcpu.php?timeout=30&`
26. [Shell 2] View docker stats to see the CPU usage go up on one of the containers.
27. [Browser] Show the dashboard to see that one of the CPU-usage-based containers has failed the health check.
28. [Shell 1] Run the health check for the CPU-usage-based container to show that it has failed:<br>`# curl http://localhost/healthcheck?server=<Container IP Address:Port>`
29. Send a request to one of the CPU-usage-based containers that uses less CPU than the threshold (35%):<br>`# curl http://localhost:8002/testcpu.php?level=2`
30. [Shell 2] View docker stats to see the CPU usage go up for one of the containers.
31. [Browser] Show the dashboard to see that no additional CPU-usage-based containers have failed the health check.
32. Make one of the memory-usage-based containers busy:<br>`# curl http://localhost:8003/testmem.php?sleep=15`
33. [Shell 2] View docker stats to see the memory usage go up on one of the containers.
34. [Browser] Show the dashboard to see that one of the memory-usage-based containers has failed the health check.
35. [Shell 1] Run the health check for the memory-usage-based container to show that it has failed:<br>`# curl http://localhost/healthcheck?server=<Container IP Address:Port>`
