# Demo to show Nginx Plus Dynamic Reconfiguration API (upstream_conf) with Consul

This demo shows NGINX Plus being used in conjuction with Consul, a service discovery platform. This demo is based on docker and spins'
up the following containers:

* [Consul](http://www.consul.io) for service discovery
* [Registrator](https://github.com/gliderlabs/registrator) to register services with Consol.  Registrator monitors for containers being started and stopped and updates Consul when a container changes state.
* [tutum/hello-world](https://registry.hub.docker.com/u/tutum/hello-world/) is a simple hello world container to simulate a service
* [google/golang-hello](https://registry.hub.docker.com/u/google/golang-hello/) a second simple hello world container to simulate another service
* and of course [NGINX Plus](http://www.nginx.com/products)

The demo is based off the work done in this blog post (to be written :P)
 
## Setup Options:

### Fully automated Vagrant/Ansible setup:

Install Vagrant using the necessary package for your OS:

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

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```~/NGINX-Demos/ansible/files/``` [Remove the files that are in there now]

1. Move into the consul-demo directory and start the Vagrant vm:

     ```
     $ cd ~/NGINX-Demos/consul-demo
     $ vagrant up
     ```
     The ```vagrant up``` command will start the virtualbox VM and provision it using the ansible playbook file ~/NGINX-Demos/ansible/setup_consul_demo.yml

1. SSH into the newly created virtual machine and move into the /vagrant directory which contains the demo files:

     ```
     $ vagrant ssh
     $ sudo su
     $ cd /vagrant
     ```

1. Execute the following two `docker exec` commands to install [jq](https://stedolan.github.io/jq/) inside consul container (This step will not be needed once this issue https://github.com/docker/compose/issues/593 is resolved)
     ```
     docker exec -ti consul apk update
     docker exec -ti consul apk add jq
     ```

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
     $ sudo git clone git@github.com:nginxinc/NGINX-Demos.git
     ```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```/srv/NGINX-Demos/ansible/files/```

1. Move into the consul-demo directory which contains the demo files and run the ansible playbook against localhost on Ubuntu VM:

     ```
     $ cd /srv/NGINX-Demos/consul-demo
     $ sudo ansible-playbook -i "localhost," -c local /srv/NGINX-Demos/ansible/setup_consul_demo.yml
     ```

1. Execute the following two `docker exec` commands to install [jq](https://stedolan.github.io/jq/) inside consul container (This step will not be needed once this issue https://github.com/docker/compose/issues/593 is resolved)
     ```
     docker exec -ti consul apk update
     docker exec -ti consul apk add jq
     ```

1. Now simply follow the steps listed under section 'Running the demo'.


### Manual Install

This section assumes that you are installing the demo on MAC OSX
#### Prerequisites and Required Software

The following software needs to be installed on your laptop:

* [Docker Toolbox](https://www.docker.com/docker-toolbox)
* [docker-compose](https://docs.docker.com/compose/install). I used [brew](http://brew.sh) to install it: `brew install docker-compose`
* [jq](https://stedolan.github.io/jq/), I used [brew](http://brew.sh) to install it: `brew install jq`

#### Setting up the demo
1. Clone demo repo

     ```$ git clone git@github.com:nginxinc/NGINX-Demos.git```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```~/NGINX-Demos/consul-demo/nginxplus/```

1. Move into the demo directory:

     ```
     $ cd ~/NGINX-Demos/consul-demo
     ```

1. If you have run this demo previously or have any docker containers running, start with a clean slate by running
     ```
     $ ./clean-containers.sh
     ```

1. NGINX Plus will be listening on port 80 on docker host, and you can get the IP address by running 
     ```
     $ docker-machine ip default
     192.168.99.100
     ```
     Export this IP into an environment variable HOST_IP `export HOST_IP=192.168.99.100` (used by docker-compose.yml below)

1. To spin up the containers run: 

     ```
     $ docker-compose build
     $ docker-compose up -d
     ```
     `docker-compose build` only needs to be run only once to build the environment.

1. Execute the following two `docker exec` commands to install [jq](https://stedolan.github.io/jq/) inside consul container (This step will not be needed once this issue https://github.com/docker/compose/issues/593 is resolved)
     ```
     docker exec -ti consul apk update
     docker exec -ti consul apk add jq
     ```

1. Now follow the steps under section 'Running the demo'

## Running the demo

1. You should have a bunch of containers up and running now:

     ```
     $ docker-compose ps
         Name                   Command                   State                    Ports
     -------------------------------------------------------------------------------------------------
     consul                   /bin/start -server       Up                       53/tcp,
                              -bootst ...                                       0.0.0.0:8600->53/udp,
                                                                                0.0.0.0:8300->8300/tcp
                                                                                , 8301/tcp, 8301/udp,
                                                                                8302/tcp, 8302/udp, 0.
                                                                                0.0.0:8400->8400/tcp,
                                                                                0.0.0.0:8500->8500/tcp
     nginx                    nginx -g daemon off;     Up                       443/tcp,
                                                                                0.0.0.0:80->80/tcp,
                                                                                0.0.0.0:8080->8080/tcp
     registrator              /bin/registrator         Up
                              consul:// ...
     service1                 /bin/sh -c php-fpm -d    Up                       0.0.0.0:8081->80/tcp
                              vari ...  
     service2                 /bin/go-run              Up                       0.0.0.0:8082->8080/tcp
     ```

1. If you followed the Fully automated Vagrant/Ansible setup option above, HOST_IP referred below is the IP assigned to your Vagrant VM (i.e 10.2.2.70 in Vagrantfile). And if you followed the Ansible only deployment option, HOST_IP will be the IP of your Ubuntu VM on which NGINX Plus is listening. For the manual install option, HOST_IP was already set above to `docker-machine ip default`

1. Go to `http://<HOST_IP>` in your favorite browser window and the main index.html with 'Welcome to nginx!' should pop up. `http://<HOST_IP>:8080/` will bring up the NGINX Plus dashboard. If you would like to see all the services registered with consul go to `http://<HOST_IP>:8500`. Going to `http://<HOST_IP>/service` will take you to one of the two hello world containers.

1. Now spin up two more containers named service3 and service4 which are the same [tutum/hello-world](https://registry.hub.docker.com/u/tutum/hello-world/) and [google/golang-hello](https://registry.hub.docker.com/u/google/golang-hello/) as above. Go to the Upstreams tab on Nginx Plus dashboard and observe the two new servers being added to the backend group.
     ```
     $ docker-compose -f add-services.yml up -d
     ```

1. Now stop any two services and observe that they get removed from the upstream group on Nginx Plus dashboard automatically
     ```
     $ docker stop service2 service4
     ```

1. Play by creating/removing/starting/stopping multiple containers. Creating a new container with SERVICE_TAG "production" or starting a stopped container will add that container to the NGINX upstream group automatically. Removing or stopping a container removes it from the upstream group.

1. The way this works is using [Watches](https://www.consul.io/docs/agent/watches.html) feature of Consul, eveytime there is a change in the list of services, a handler (script.sh) is invoked. This bash script gets the list of all Nginx Plus upstreams using its status and upstream_conf APIs, loops through all the containers registered with consul which are tagged with SERVICE_TAG "production" using this [Consul API](https://www.consul.io/docs/agent/http/catalog.html#catalog_services) and adds them to the upstream group using upstream_conf API if not present already. It also removes the upstreams from Nginx upstream group which are not registered in Consul. 

All the changes should be automatically reflected in the NGINX config and show up on the NGINX Plus Dashboard.
