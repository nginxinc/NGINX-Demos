# Demo to show Dynamic Reconfiguration of Upstream servers in NGINX Plus using Consul's DNS interface

This demo shows NGINX Plus being used in conjuction with [Consul's DNS interface](https://www.consul.io/docs/agent/dns.html). This demo is based on docker and spins'
up the following containers:

* [Consul](http://www.consul.io) for service discovery using DNS
* [Registrator](https://github.com/gliderlabs/registrator) to register services with Consul.  Registrator monitors for containers being started and stopped and updates Consul when a container changes state.
* [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) as a NGINX webserver that serves a simple page containing its hostname, IP address and port to simulate backend servers
* and of course [NGINX Plus](http://www.nginx.com/products) R9 which adds support for DNS lookups over TCP & DNS SRV records

The demo is based off the work described in this blog post: TBD
 
### Manual Install

#### Prerequisites and Required Software

The following software needs to be installed on your laptop:

* [Docker Toolbox](https://www.docker.com/docker-toolbox)
* [docker-compose](https://docs.docker.com/compose/install). I used [brew](http://brew.sh) to install it: `brew install docker-compose`

#### Setting up the demo
1. Clone demo repo

     ```$ git clone git@github.com:nginxinc/NGINX-Demos.git```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```~/NGINX-Demos/consul-dns-srv-demo/nginxplus/```

1. Move into the demo directory:

     ```
     $ cd ~/NGINX-Demos/consul-dns-srv-demo
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

1. Spin up Consul, Registrator, NGINX Plus & http service containers: 

     ```
     $ docker-compose up -d
     ```

1. Now follow the steps under section 'Running the demo'

## Running the demo

1. You should have a bunch of containers up and running now:

     ```
     $ docker ps
     CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                                                                                                                              NAMES
     765bc1517305        consuldnssrvdemo_nginxplus     "nginx -g 'daemon off"   31 minutes ago      Up 31 minutes       0.0.0.0:80->80/tcp, 0.0.0.0:8080->8080/tcp, 443/tcp                                                                                                nginxplus
     ec1cc90d189e        nginxdemos/hello:latest         "nginx -g 'daemon off"   31 minutes ago      Up 31 minutes       443/tcp, 0.0.0.0:32790->80/tcp                                                                                                                     consuldnssrvdemo_http_1
     8b3c15c37bee        gliderlabs/registrator:latest   "/bin/registrator con"   31 minutes ago      Up 31 minutes                                                                                                                                                          registrator
     4718ed726d26        progrium/consul:latest          "/bin/start -server -"   31 minutes ago      Up 31 minutes       0.0.0.0:8300->8300/tcp, 0.0.0.0:8400->8400/tcp, 0.0.0.0:8500->8500/tcp, 8301-8302/tcp, 8301-8302/udp, 0.0.0.0:8600->53/tcp, 0.0.0.0:8600->53/udp   consul
     ```

1. Go to `http://<HOST_IP>` in your favorite browser window and that will take you to the nginx-hello container printing its hostname, IP Address and the port of the container. `http://<HOST_IP>:8080/` will bring up the NGINX Plus dashboard with the Server Zones & Upstreams tab. The configuration file NGINX Plus is using here is /etc/nginx/conf.d/app.conf which is included from /etc/nginx/nginx.conf. If you would like to see all the services registered with consul go to `http://<HOST_IP>:8500`.

1. Now scale up and scale down the http service which is the same [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) as above. Go to the Upstreams tab on Nginx Plus dashboard and observe the change in the list of servers being added to the backend group.
     ```
     $ docker-compose scale http=5
     $ docker-compose scale http=3
     ```

1. We are using the SRV RR support for the "server" directive of http upstream module and DNS lookups over TCP feature introduced in NGINX Plus R9. This means that NGINX Plus can now ask for the SRV record (port,weight etc) in the DNS query and also switch the DNS query over TCP automatically if it receives a truncated DNS response over UDP.
     
     ```
     resolver 172.17.42.1:8600 valid=10s;
     upstream backend {
          zone upstream_backend 64k;
          server service.consul service=http resolve;
     }
     ```

All the changes should be automatically reflected in the NGINX config and show up on the NGINX Plus Dashboard.
