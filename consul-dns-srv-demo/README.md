# Demo to show Dynamic Reconfiguration of Upstream servers in NGINX Plus using Consul's DNS interface

This demo shows NGINX Plus being used in conjuction with [Consul's DNS interface](https://www.consul.io/docs/agent/dns.html). This demo is based on docker and spins'
up the following containers:

*   [Consul](http://www.consul.io) for service discovery using DNS
*   [Registrator](https://github.com/gliderlabs/registrator) to register services with Consul.  Registrator monitors for containers being started and stopped and updates Consul when a container changes state.
*   [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) as a NGINX webserver that serves a simple page containing its hostname, IP address and port to simulate backend servers
*   [NGINX Plus](http://www.nginx.com/products) (R13 or higher) which adds support for DNS lookups over TCP & DNS SRV records

The demo is based off the work described in this blog post: [Service Discovery for NGINX Plus Using DNS SRV Records from Consul](https://www.nginx.com/blog/service-discovery-nginx-plus-srv-records-consul-dns/)

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

4.  Copy `nginx-repo.key` and `nginx-repo.crt` files for your account to `~/NGINX-Demos/consul-dns-srv-demo/nginxplus`

5.  Move into the consul-dns-srv-demo directory and start the Vagrant vm:

    ```
    $ cd ~/NGINX-Demos/consul-dns-srv-demo
    $ vagrant up
    ```

    The `vagrant up` command will start the virtualbox VM and provision it using the ansible playbook file `~/NGINX-Demos/consul-dns-srv-demo/setup_consul_dns_srv_demo.yml`. The ansible playbook file also invokes another script `provision.sh` which sets the HOST_IP environment variable to the IP address of the `enp0s8` interface (10.2.2.70 in this case - assigned in the Vagrantfile) and invokes the `docker-compose up -d` command.

6.  SSH into the newly created virtual machine and move into the /vagrant directory which contains the demo files:

    ```
    $ vagrant ssh
    $ sudo su
    ```

    The demo files will be in `/srv/NGINX-Demos/consul-dns-srv-demo`

7.  Now simply follow the steps listed under section 'Running the demo'.

### Ansible only deployment

1.  Create Ubuntu 18.04 VM

2.  Install Ansible on Ubuntu VM

    `$ sudo apt-get install ansible`

3.  Clone demo repo into `/srv` on Ubuntu VM:

    ```
    $ cd /srv
    $ sudo git clone https://github.com/nginxinc/NGINX-Demos.git
    ```

4.  Copy `nginx-repo.key` and `nginx-repo.crt` files for your account to `/srv/NGINX-Demos/consul-dns-srv-demo/nginxplus`

5.  Move into the consul-dns-srv-demo directory which contains the demo files and make sure the IP address of your Ubuntu VM on which NGINX Plus will be listening is assigned to the `enp0s8` interface. If in case you need to use IP of another interface, replace `enp0s8` on line 6 of `provision.sh` with the corresponding interface name

     `$ cd /srv/NGINX-Demos/consul-dns-srv-demo`

6.  Run the ansible playbook against localhost on Ubuntu VM:

    `$ sudo ansible-playbook -i "localhost," -c local /srv/NGINX-Demos/consul-dns-srv-demo/setup_consul_dns_srv_demo.yml`

7.  Now simply follow the steps listed under section 'Running the demo'.

### Manual Install

#### Prerequisites and Required Software

The following software needs to be installed:

*   [Docker for Mac](https://www.docker.com/products/docker#/mac) if you are running this locally on your MAC **OR** [docker-compose](https://docs.docker.com/compose/install) if you are running this on a linux VM

#### Setting up the demo

1.  Clone demo repo

    `$ git clone https://github.com/nginxinc/NGINX-Demos.git`

2.  Copy `nginx-repo.key` and `nginx-repo.crt` files for your account to `~/NGINX-Demos/consul-dns-srv-demo/nginxplus/`

3.  Move into the demo directory:

    `$ cd ~/NGINX-Demos/consul-dns-srv-demo`

4.  If you have run this demo previously or have any docker containers running, start with a clean slate by running

    `$ ./clean-containers.sh`

5.  NGINX Plus will be listening on port 80 on docker host.

    1.  If you are using Docker Toolbox, you can get the IP address of your docker-machine (default here) by running

    ```
    $ docker-machine ip default
    192.168.99.100
    ```

    2.  If you are using Docker for Mac, the IP address you need to use is 172.17.0.1

    Export this IP into an environment variable named HOST_IP by running `export HOST_IP=x.x.x.x` command. This variable is used by the `docker-compose.yml` file

6.  Spin up Consul, Registrator, NGINX Plus & http service containers:

    `$ docker-compose up -d`

7.  Now follow the steps under section 'Running the demo'

## Running the demo

1.  You should have a bunch of containers up and running now:

    ```
    $ docker ps
    CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                                                                                                                              NAMES
    765bc1517305        consuldnssrvdemo_nginxplus     "nginx -g 'daemon off"   31 minutes ago      Up 31 minutes       0.0.0.0:80->80/tcp, 0.0.0.0:8080->8080/tcp, 443/tcp                                                                                                nginxplus
    ec1cc90d189e        nginxdemos/hello:latest         "nginx -g 'daemon off"   31 minutes ago      Up 31 minutes       443/tcp, 0.0.0.0:32790->80/tcp                                                                                                                     consuldnssrvdemo_http_1
    8b3c15c37bee        gliderlabs/registrator:latest   "/bin/registrator con"   31 minutes ago      Up 31 minutes                                                                                                                                                          registrator
    4718ed726d26        progrium/consul:latest          "/bin/start -server -"   31 minutes ago      Up 31 minutes       0.0.0.0:8300->8300/tcp, 0.0.0.0:8400->8400/tcp, 0.0.0.0:8500->8500/tcp, 8301-8302/tcp, 8301-8302/udp, 0.0.0.0:8600->53/tcp, 0.0.0.0:8600->53/udp   consul
    ```

2.  Go to `http://<HOST_IP>` in your favorite browser window and that will take you to the nginx-hello container printing its hostname, IP Address and the port of the container. `http://<HOST_IP>:8080/` will bring up the NGINX Plus dashboard with the Server Zones & Upstreams tab. The configuration file NGINX Plus is using here is /etc/nginx/conf.d/app.conf which is included from /etc/nginx/nginx.conf. If you would like to see all the services registered with consul go to `http://<HOST_IP>:8500`.

3.  Now scale up and scale down the http service which is the same [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) as above. Go to the Upstreams tab on Nginx Plus dashboard and observe the change in the list of servers being added/removed from the backend group.

    ```
    $ docker-compose scale http=5
    $ docker-compose scale http=3
    ```

4.  We are using the DNS SRV records using the `service` parameter for the `server` directive of http upstream module and DNS lookups over TCP features introduced in NGINX Plus R9. This means that NGINX Plus can now ask for the SRV record (port, weight, etc...) in the DNS query and also switch the DNS query over TCP automatically if it receives a truncated DNS response over UDP.

    ```
    resolver consul:53 valid=2s;
    resolver_timeout 2s;

    upstream backend {
        zone upstream_backend 64k;
        server service.consul service=http resolve;
    }
    ```

All the changes should be automatically reflected in the NGINX config and show up on the NGINX Plus Dashboard.
