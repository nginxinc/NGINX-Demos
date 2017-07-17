# Demo to show Redis Load balancing with NGINX Plus

This demo is based on docker and spins up the following containers:

* [Redis](https://redis.io/) which is a popular open source in-memory database. We create 1 master & 2 slave containers
* [Redis Sentinel](https://redis.io/topics/sentinel) which is used to provide HA and clustering for Redis
* and of course [NGINX Plus](http://www.nginx.com/products) which will be used as a TCP load balancer for the Redis nodes

The demo is based off the work described in this blog post: [Load Balancing Redis with NGINX Plus](Add Link later)

### Manual Install

#### Prerequisites and Required Software

The following software needs to be installed:

* [Docker for Mac](https://www.docker.com/products/docker#/mac) if you are running this locally on your MAC **OR** [docker-compose](https://docs.docker.com/compose/install) if you are running this on a linux VM
* [redis-cli](https://redis.io/topics/rediscli) on the Docker host

#### Setting up the demo
1. Clone demo repo

     ```$ git clone https://github.com/nginxinc/NGINX-Demos.git```

1. Copy ```nginx-repo.key``` and ```nginx-repo.crt``` files for your account to ```~/NGINX-Demos/redis-demo/nginxplus/```

1. Move into the demo directory

     ```
     $ cd ~/NGINX-Demos/redis-demo
     ```

1. If you have run this demo previously or have any docker containers running, start with a clean slate by running
     ```
     $ ./clean-containers.sh
     ```

1. Spin up Redis, Sentinel and NGINX Plus containers 

     ```
     $ docker-compose up -d
     ```

1. Now follow the steps under section 'Running the demo'

## Running the demo

1. You should have a bunch of containers up and running now:

     ```
     $ docker ps
     CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS                                                             NAMES
     578f9e662203        redisdemo_sentinel    "sentinel-entrypoi..."   4 seconds ago       Up 3 seconds        6379/tcp, 26379/tcp                              redisdemo_sentinel_1
     7aeee69035e7        redis:3               "docker-entrypoint..."   5 seconds ago       Up 4 seconds        0.0.0.0:63793->6379/tcp                          redis-slave2
     77530c277fdd        redis:3               "docker-entrypoint..."   5 seconds ago       Up 4 seconds        0.0.0.0:63792->6379/tcp                          redis-slave1
     4c06e6236587        redisdemo_nginxplus   "nginx -g 'daemon ..."   6 seconds ago       Up 5 seconds        0.0.0.0:6379->6379/tcp, 0.0.0.0:8080->8080/tcp   nginxplus
     0ab4d54bd353        redis:3               "docker-entrypoint..."   6 seconds ago       Up 5 seconds        0.0.0.0:63791->6379/tcp                          redis-master
     ```

     NGINX Plus is listening on TCP port 6379 on the docker host which is the standard Redis port and load balance the traffic across the 3 Redis containers (one Master & two Slave). One Redis Sentinel container which is used to set up Clustering and for providing High Availability. 

1. Go to the NGINX Plus Monitoring dashboard by going to http://127.0.0.1:8080 in your favourite web browser if you used Docker for Mac. If you set this up on a Linux VM, replace 127.0.0.1 with the IP address of your Linux VM. You will see all 3 Redis containers under TCP/UDP Upstreams

1. Now run `redis-cli -h <DOCKER-HOST-IP>` and execute couple of different Redis commands. After executing each redis command, notice the number of 'Active' & 'Total' connections getting incremented in the Dashboard for each upstream Redis node in a round-robin manner. This is because of the default round-robin LB
     ```
     $ redis-cli -h 127.0.0.1
     127.0.0.1:6379> info replication
     # Replication  
     
     role:master
     connected_slaves:2
     slave0:ip=172.17.0.2,port=6379,state=online,offset=901913,lag=0
     slave1:ip=172.17.0.4,port=6379,state=online,offset=901778,lag=1
     master_repl_offset:901913
     repl_backlog_active:1
     repl_backlog_size:1048576
     repl_backlog_first_byte_offset:2
     repl_backlog_histlen:901912
     127.0.0.1:6379>
     127.0.0.1:6379> set foo abc
     (error) READONLY You can't write against a read only slave.
     127.0.0.1:6379> set foo abc
     OK
     127.0.0.1:6379>
     127.0.0.1:6379> get foo
     "abc"
     127.0.0.1:6379> config get maxclients
     1) "maxclients"
     2) "10000"
      ```

1. Notice above that the 'set foo abc' command fails once since it lands on the Redis slave which cannot handle SET. It succeeds on the 2nd attempt when it lands on the Redis master. You could do GET/SET splits by configuring 2 virtual servers listening on 2 different ports (one for GET & another for SET) & then proxy_pass to just the Redis master in case of SET and to all Redis nodes in case of GET

