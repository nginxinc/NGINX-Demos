# Demo to show NGINX Plus Dynamic Reconfiguration API with Zookeeper

This demo shows NGINX Plus being used in conjuction with Apache Zookeeper, which can be used for service discovery. This demo is based on docker and spins'
up the following containers:

*   [Zookeeper](https://zookeeper.apache.org/) for service discovery. Hereby referred as ZK
*   [Registrator](https://github.com/gliderlabs/registrator), a service registry bridge for docker with a pluggable adapter for ZK backend. It monitors state change of service containers and updates ZK.
*   [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) as a NGINX webserver that serves a simple page containing its hostname, IP address and port to simulate backend servers
*   [NGINX Plus](http://www.nginx.com/products) (R13 or higher)

The demo is based off the work described in this blog post: [Service Discovery with NGINX Plus and Zookeeper](https://www.nginx.com/blog/service-discovery-nginx-plus-zookeeper/)

## Setup Options:

### Fully automated Vagrant/Ansible setup:

Install Vagrant using the necessary package for your OS:

<https://www.vagrantup.com/downloads.html>

1.  Install provider for vagrant to use to start VM's.

    The default provider is VirtualBox (Note that only VirtualBox versions 4.0 and higher are supported), which can be downloaded from the following link:

    <https://www.virtualbox.org/wiki/Downloads>

     A full list of providers can be found at the following page, if you do not want to use VirtualBox:

    <https://docs.vagrantup.com/v2/providers/>

2.  Install Ansible:

    <http://docs.ansible.com/ansible/intro_installation.html>

3.  Clone demo repo

    `$ git clone https://github.com/nginxinc/NGINX-Demos.git`

4.  Copy `nginx-repo.key` and `nginx-repo.crt` files for your account to `~/NGINX-Demos/zookeeper-demo/nginxplus`

5.  Move into the zookeeper-demo directory and start the Vagrant vm:

    ```
    $ cd ~/NGINX-Demos/zookeeper-demo
    $ vagrant up
    ```

    The `vagrant up` command will start the virtualbox VM and provision it using the ansible playbook file `~/NGINX-Demos/zookeeper-demo/setup_zookeeper_demo.yml`. The ansible playbook file also invokes another script provision.sh which sets the HOST_IP environment variable to the IP address of the eth1 interface (10.2.2.70 in this case assigned in the Vagrantfile) and invokes the `docker-compose up -d` command

6.  SSH into the newly created virtual machine and move into the /vagrant directory which contains the demo files:

    ```
    $ vagrant ssh
    $ sudo su
    ```

    The demo files will be in `/srv/NGINX-Demos/zookeeper-demo`

7.  Now simply follow the steps listed under section 'Running the demo'.

### Ansible only deployment

1.  Create Ubuntu 18.04 LTS VM

2.  Install Ansible on Ubuntu VM

    `$ sudo apt-get install ansible`

3.  Clone demo repo into `/srv` on Ubuntu VM:

    ```
    $ cd /srv
    $ sudo git clone https://github.com/nginxinc/NGINX-Demos.git
    ```

4.  Copy `nginx-repo.key` and `nginx-repo.crt` files for your account to `/srv/NGINX-Demos/zookeeper-demo/nginxplus`

5.  Move into zookeeper-demo directory and set the HOST_IP environment variable to the public IP of your ubuntu VM

    ```
    $ cd /srv/NGINX-Demos/zookeeper-demo
    $ export HOST_IP=x.x.x.x
    ```

6.  Run the ansible playbook against localhost on Ubuntu VM:

    `$ sudo ansible-playbook -i "localhost," -c local /srv/NGINX-Demos/zookeeper-demo/setup_zookeeper_demo.yml`

7.  Now simply follow the steps listed under section 'Running the demo'.

### Manual Install

#### Prerequisites and Required Software

The following software needs to be installed:

*   [Docker for Mac](https://www.docker.com/products/docker#/mac) if you are running this locally on your MAC **OR** [docker-compose](https://docs.docker.com/compose/install) if you are running this on a linux VM

As the demo uses NGINX Plus a `nginx-repo.crt` and `nginx-repo.key` needs to be copied into the `nginxplus/` directory

#### Setting up the demo

1.  Clone demo repo

    `$ git clone https://github.com/nginxinc/NGINX-Demos.git`

2.  Copy `nginx-repo.key` and `nginx-repo.crt` files for your account to `~/NGINX-Demos/zookeeper-demo/nginxplus/`

3.  Move into the demo directory:

    `$ cd ~/NGINX-Demos/zookeeper-demo`

4.  If you have run this demo previously or have any docker containers running, start with a clean slate by running

    `$ ./clean-containers.sh`

5.  NGINX Plus will be listening on port 80 on your docker host.

    1.  If you are using Docker Toolbox, you can get the IP address of your docker-machine (default here) by running

    ```
    $ docker-machine ip default
    192.168.99.100
    ```

    2.  If you are using Docker for Mac, the IP address you need to use is 172.17.0.1

    **Export this IP into an environment variable named HOST_IP by running `export HOST_IP=x.x.x.x` command. This variable is used by docker-compose.yml file**

6.  Spin up the zookeeper, Registrator and NGINX Plus containers first:

    `$ docker-compose up -d`

7.  Now cd into zookeeper directoy and execute the following two `docker exec` commands. The first one is to create a /services path under ZK and the second one is to watch for changes (additions/deletions under the /services/http path in ZK). It triggers script.sh whenever a change in the number of http service containers is detected

    ```
    $ cd zookeeper
    $ docker exec -ti zookeeper ./zk-tool create /services -d abc
    $ docker exec -ti zookeeper ./zk-tool watch-children /services/http
    ```

8.  Now in a different tab in the zookeeper-demo directory, spin up the nginxdemos/hello container which is the backend http service

    `$ docker-compose -f create-http-service.yml up -d`

9.  Now follow the steps under section 'Running the demo'

## Running the demo

1.  You should have a bunch of containers up and running now:

    ```
    $ docker ps
    CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                                                                            NAMES
    ed66c3ac7563        nginxdemos/hello:latest         "nginx -g 'daemon ..."   6 minutes ago       Up 6 minutes        443/tcp, 0.0.0.0:32778->80/tcp                                                                   zookeeperdemo_http_1
    142d64081f2b        gliderlabs/registrator:latest   "/bin/registrator ..."   9 minutes ago       Up 9 minutes                                                                                                         registrator
    4abcc06eb1bd        zookeeperdemo_nginxplus         "nginx -g 'daemon ..."   9 minutes ago       Up 9 minutes        0.0.0.0:80->80/tcp, 0.0.0.0:8080->8080/tcp, 443/tcp                                              nginxplus
    69be5bf69e8c        zookeeperdemo_zookeeper         "/opt/zookeeper/bi..."   9 minutes ago       Up 9 minutes        0.0.0.0:2181->2181/tcp, 0.0.0.0:2888->2888/tcp, 0.0.0.0:3888->3888/tcp, 0.0.0.0:9888->9888/tcp   zookeeper
    ```

2.  Go to `http://<HOST-IP>` (Note: Docker for Mac runs on IP address 127.0.0.1) in your favorite browser window and it will take you to one of the two NGINX hello containers printing its hostname, IP Address and port number, request URI, local time of the webserver and the client IP address. `http://<HOST-IP>:8080/` will bring up the NGINX Plus dashboard. The configuration file NGINX Plus is using here is `/etc/nginx/conf.d/app.conf` which is included from `/etc/nginx/nginx.conf`.

3.  Now scale up and scale down the http service using the commands below. Go to the Upstreams tab on Nginx Plus dashboard and observe the change in the list of servers being added/removed from the backend group accordingly.

    ```
    $ docker-compose -f create-http-service.yml up -d --scale http=5
    $ docker-compose -f create-http-service.yml up -d --scale http=3
    ```

4.  The way this works is using [Watches](https://zookeeper.apache.org/doc/trunk/zookeeperProgrammers.html#sc_zkDataMode_watches) feature of Zookeeper, eveytime there is a change in the list of services, a handler (`script.sh`) is invoked through zk-tool. This bash script gets the list of all Nginx Plus upstreams using its status and upstream_conf APIs, loops through all the containers registered with ZK which are tagged with SERVICE_TAG "production" using 'zk-tool list /services'. and adds them to the upstream group using upstream_conf API if not present already. It also removes the upstreams from Nginx upstream group which are not present in ZK.

All the changes should be automatically reflected in the NGINX config and show up on the NGINX Plus Dashboard.
