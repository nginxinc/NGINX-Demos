# Demo to show Nginx Plus Dynamic Reconfiguration API (upstream_conf) with Consul

This demo shows NGINX Plus being used in conjuction with Consul, a service discovery platform. This demo is based on docker and spins'
up the following containers:

* [Consul](http://www.consul.io) for service discovery
* [Registrator](https://github.com/gliderlabs/registrator) to register services with Consul.  Registrator monitors for containers being started and stopped and updates Consul when a container changes state.
* [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) as a NGINX webserver that serves a simple page containing its hostname, IP address and port, request URI, local time of the webserver and the client IP address. This is to simulate backend servers NGINX Plus will be load balancing across.
* and of course [NGINX Plus](http://www.nginx.com/products) (R8 or higher)

The demo is based off the work described in this blog post: [Service Discovery with NGINX Plus and Consul](https://www.nginx.com/blog/service-discovery-with-nginx-plus-and-consul/)
 
## Setup Options:

### Fully automated Vagrant/Ansible setup:

Install Vagrant using the necessary package for your OS:

https://www.vagrantup.com/downloads.html

1. Install provider for vagrant to use to start VM's.  

     The default provider is VirtualBox [Note that only VirtualBox versions 4.0 and higher are supported], which can be downloaded from the following link:

     https://www.virtualbox.org/wiki/Downloads

     A full list of providers can be found at the following page, if you do not want to use VirtualBox:

     https://docs.vagrantup.com/v2/providers/

1. Install Ansible:

     http://docs.ansible.com/ansible/intro_installation.html

1. Clone demo repo

     ```$ git clone https://github.com/nginxinc/NGINX-Demos.git```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```~/NGINX-Demos/ansible/files/```

1. Move into the consul-api-demo directory and start the Vagrant vm:

     ```
     $ cd ~/NGINX-Demos/consul-api-demo
     $ vagrant up
     ```
     The ```vagrant up``` command will start the virtualbox VM and provision it using the ansible playbook file ~/NGINX-Demos/ansible/setup_consul_demo.yml. The ansible playbook file also invokes another script provision.sh which sets the HOST_IP environment variable to the IP address of the eth1 interface (10.2.2.70 in this case assigned in the Vagrantfile) and invokes the ```docker-compose up -d``` command

1. SSH into the newly created virtual machine and move into the /vagrant directory which contains the demo files:

     ```
     $ vagrant ssh
     $ sudo su
     ```
The demo files will be in /srv/NGINX-Demos/consul-api-demo

1. Now simply follow the steps listed under section 'Running the demo'.


### Ansible only deployment

1. Create Ubuntu 14.04 VM 

1. Install Ansible on Ubuntu VM

     ```
     $ sudo apt-get install ansible
     ```

1. Clone demo repo into ```/srv``` on Ubuntu VM:

     ```
     $ cd /srv
     $ sudo git clone https://github.com/nginxinc/NGINX-Demos.git
     ```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```/srv/NGINX-Demos/ansible/files/```

1. Move into the consul-api-demo directory which contains the demo files and make sure the IP address of your Ubuntu VM on which NGINX Plus will be listening is assigned to the ```eth1``` interface. If in case you need to use IP of another interface, replace ```eth1``` on line 6 of provision.sh with the corresponding interface name
     ```
     $ cd /srv/NGINX-Demos/consul-api-demo
     ```

1. Run the ansible playbook against localhost on Ubuntu VM:

     ```
     $ sudo ansible-playbook -i "localhost," -c local /srv/NGINX-Demos/ansible/setup_consul_demo.yml
     ```

1. Now simply follow the steps listed under section 'Running the demo'.


### Manual Install

#### Prerequisites and Required Software

The following software needs to be installed on your laptop:

* [Docker Toolbox](https://www.docker.com/docker-toolbox) OR [Docker for Mac](https://www.docker.com/products/docker#/mac)
* [docker-compose](https://docs.docker.com/compose/install). I used [brew](http://brew.sh) to install it: `brew install docker-compose`
* [jq](https://stedolan.github.io/jq/), I used [brew](http://brew.sh) to install it: `brew install jq`

#### Setting up the demo
1. Clone demo repo

     ```$ git clone https://github.com/nginxinc/NGINX-Demos.git```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```~/NGINX-Demos/consul-api-demo/nginxplus/```

1. Move into the demo directory:

     ```
     $ cd ~/NGINX-Demos/consul-api-demo
     ```

1. If you have run this demo previously or have any docker containers running, start with a clean slate by running
     ```
     $ ./clean_containers.sh
     ```

1. NGINX Plus will be listening on port 80 on your docker host.
     1. If you are using Docker Toolbox, you can get the IP address of your docker-machine (default here) by running 

     ```
     $ docker-machine ip default
     192.168.99.100
     ```
     1. If you are using Docker for Mac, the IP address you need to use is 172.17.0.1

   Export this IP into an environment variable named HOST_IP by running `export HOST_IP=x.x.x.x` command. This variable is used by docker-compose.yml file

1. Spin up the Consul, Registrator and NGINX Plus containers first: 

     ```
     $ docker-compose up -d
     ```

1. Execute the following two `docker exec` commands to install [jq](https://stedolan.github.io/jq/) inside consul container
     ```
     docker exec -ti consul apk update
     docker exec -ti consul apk add jq
     ```

1. Spin up the nginxdemos/hello container which is the backend http service
     ```
     $ docker-compose -f create-http-service.yml up -d
     ```

1. Now follow the steps under section 'Running the demo'

## Running the demo

1. You should have a bunch of containers up and running now:

     ```
     $ docker ps
     CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                                                                                                                NAMES
     b663f7ac70be        nginxdemos/hello:latest         "nginx -g 'daemon off"   About an hour ago   Up About an hour    443/tcp, 0.0.0.0:32800->80/tcp                                                                                                       consulapidemo_http_1
     7d6a66acff99        consulapidemo_nginxplus         "nginx -g 'daemon off"   About an hour ago   Up About an hour    0.0.0.0:80->80/tcp, 0.0.0.0:8080->8080/tcp, 443/tcp                                                                                  nginxplus
     2059ad9a7926        gliderlabs/registrator:latest   "/bin/registrator con"   About an hour ago   Up About an hour                                                                                                                                         registrator
     dd4b1101bb66        progrium/consul:latest          "/bin/start -server -"   About an hour ago   Up About an hour    53/tcp, 0.0.0.0:8300->8300/tcp, 0.0.0.0:8400->8400/tcp, 8301-8302/tcp, 0.0.0.0:8500->8500/tcp, 8301-8302/udp, 0.0.0.0:8600->53/udp   consul
     ```

1. If you followed the Fully automated Vagrant/Ansible setup option above, HOST_IP referred below is the IP assigned to your Vagrant VM (i.e 10.2.2.70 in Vagrantfile) and is set already. And if you followed the Ansible only deployment option, HOST_IP will be the IP of your Ubuntu VM on which NGINX Plus is listening (IP of the interface set on line 6 of provision.sh, set to eth1 by default). For the manual install option, HOST_IP was already set above.

1. Go to `http://<DOCKER-HOST-IP>` (Note: Docker for Mac runs on IP address 127.0.0.1) in your favorite browser window and that will take you to the hello container printing its hostname, IP Address and port number, request URI, local time of the webserver and the client IP address. `http://<DOCKER-HOST-IP>:8080/` will bring up the NGINX Plus dashboard. The configuration file NGINX Plus is using here is /etc/nginx/conf.d/app.conf which is included from /etc/nginx/nginx.conf. If you would like to see all the services registered with consul go to `http://<DOCKER-HOST-IP>:8500`. **We are also using the persistent on-the-fly reconfiguration feature introduced in NGINX Plus R8. This means that NGINX Plus saves all the changes made by the upstream_conf API across reloads by writing it to a file on disk specified using the [state](http://nginx.org/en/docs/http/ngx_http_upstream_module.html#state) directive.**

1. Now scale up and scale down the http service using the commands below. Go to the Upstreams tab on Nginx Plus dashboard and observe the change in the list of servers being added/removed from the backend group accordingly.
     ```
     $ docker-compose -f create-http-service.yml scale http=5
     $ docker-compose -f create-http-service.yml scale http=3
     ```

1. The way this works is using [Consul Watches](https://www.consul.io/docs/agent/watches.html), eveytime there is a change in the number of containers running the http service, an external handler which is a simple bash script (script.sh) gets invoked. This script gets the list of all Nginx Plus upstreams using its status and upstream_conf APIs, loops through all the http service containers registered with consul and adds them to the upstream group using upstream_conf API if not present already. It also removes the upstreams which are not present in Consul from Nginx upstream group. 

All the changes should be automatically reflected in the NGINX config and show up on the NGINX Plus Dashboard.
