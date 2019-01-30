# Demo to show Dynamic Reconfiguration of Upstream servers with open source NGINX using Consul & Consul-Template

This demo shows NGINX being used in conjuction with Consul, a popular Service discovery platform and Consul-Template, a generic template rendering tool that provides a convenient way to populate values from Consul into the file system using a daemon.

This demo is based on docker and spins' up the following containers:

*   [Consul](http://www.consul.io) for service discovery
*   [Registrator](https://github.com/gliderlabs/registrator) to register services with Consul. Registrator monitors for containers being started and stopped and updates Consul when a container changes state.
*   [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) as a NGINX webserver that serves a simple page containing its hostname, IP address and port, request URI, local time of the webserver and the client IP address. This is to simulate backend servers NGINX will be load balancing across.
*   [NGINX](http://nginx.org/) Open Source.

## Prerequisites and Required Software

The following software needs to be installed:

*   [Docker for Mac](https://www.docker.com/products/docker#/mac) if you are running this locally on your MAC **OR** [docker-compose](https://docs.docker.com/compose/install) if you are running this on a linux VM

## Setting up the demo

1.  NGINX will be listening on port 80 on your docker host.

    1.  If you are using Docker Toolbox, you can get the IP address of your docker-machine (default here) by running

    ```
    $ docker-machine ip default
    192.168.99.100
    ```

    2.  If you are using Docker for Mac, the IP address you need to use is 172.17.0.1

    Export this IP into an environment variable HOST_IP by running `export HOST_IP=192.168.99.100` OR `export HOST_IP=172.17.0.1` (used by docker-compose.yml below)

2.  Now to spin up all the containers run:

    `$ docker-compose up -d`

    You should have a bunch of containers up and running:

    ```
    $ docker ps
    CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                                                                                                                NAMES
    aea80813b12d        consultemplatedemo_nginx        "/usr/bin/runsvdir /e"   3 days ago          Up 25 seconds       0.0.0.0:80->80/tcp, 443/tcp                                                                                                          nginx
    08c5a8cec952        gliderlabs/registrator:latest   "/bin/registrator -in"   3 days ago          Up 25 seconds                                                                                                                                            registrator
    5a7bf3bb3a25        progrium/consul                 "/bin/start -server -"   3 days ago          Up 26 seconds       53/tcp, 0.0.0.0:8300->8300/tcp, 0.0.0.0:8400->8400/tcp, 8301-8302/tcp, 0.0.0.0:8500->8500/tcp, 8301-8302/udp, 0.0.0.0:8600->53/udp   consul
    a95c766b8ab5        nginxdemos/hello:latest         "nginx -g 'daemon off"   3 days ago          Up 25 seconds       443/tcp, 0.0.0.0:32846->80/tcp                                                                                                       consultemplatedemo_http_1
    ```

## Running the demo

NGINX is listening on port 80 on your Docker Host, and runs Consul Template. Consul Template listens to Consul for changes to the service catalog, rewrites Nginx config file and reloads Nginx on any changes.

So now just go to `http://<HOST-IP>` (Note: Docker for Mac runs on IP address 127.0.0.1) and the main index.html should pop up with a list of the services that have been disovered. There should be a single `http` service. Clicking on that link will take you to the Consul UI page showing the list of all registered services.

From here you can scale up the http service:

```
$ docker-compose scale http=5
Creating and starting consultemplatedemo_http_2 ... done
Creating and starting consultemplatedemo_http_3 ... done
Creating and starting consultemplatedemo_http_4 ... done
Creating and starting consultemplatedemo_http_5 ... done
```

Scale it down:

```
$ docker-compose scale http=3
Stopping and removing consultemplatedemo_http_4 ... done
Stopping and removing consultemplatedemo_http_5 ... done
```

All the changes should be automatically reflected in the NGINX config file (/etc/nginx/conf.d/app.conf) inside the NGINX container.

Another feature we are using here is the HTTP health checks with Consul. Registrator allows to specify these health checks by using extra metadata in labels for your service. More details on this can be found [here](http://gliderlabs.com/registrator/latest/user/backends/#consul). With the following two labels (SERVICE_80_CHECK_HTTP: /http and SERVICE_80_CHECK_INTERVAL: 5s) applied to our http service in the docker-compose.yml file, Consul sends a /http request to all http containers every 5 seconds and expects a 200 OK response in return for a container to be considered healthy. If a 200 OK is not received, the container will be removed from Consul and in turn gremoved from upstream block within NGINX configuration as well.

So lets stop a container and see if it gets removed from the load balancing pool

```
$ docker stop consultemplatedemo_http_2
consultemplatedemo_http_2
```

On the Consul UI page (http://<HOST-IP>:8500/ui/#/dc1/services/http), you will observe the change and the container removed. Also the NGINX config file (`/etc/nginx/conf.d/app.conf`) will have just 2 server entries now indicating that the 3rd server entry corresponding to the container which was stopped was removed automatically.
