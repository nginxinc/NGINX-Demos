# Misc NGINX Demos from conferences showing different functionality of NGINX and NGINX Plus

*   **autoscaling-demo**: This demo uses one NGINX Plus instance as a load balancer with two upstream groups, one for NGINX Plus web servers and one for Elasticsearch nodes.  All of the instances run in Docker containers. The demo uses both the upstream_conf and status api's.  If shows creating a new NGINX Plus environment and adding and removing containers manually and with autoscaling.

*   **aws-nlb-ha-asg**: This demo contains a series of scripts that enable an easy deployment of a High Availability All Active Auto Scaling NGINX Plus Load Balancing configuration on AWS.

*   **consul-api-demo**: This demo spins up a bunch of docker containers and shows NGINX Plus being used in conjuction with Consul, a service discovery platform. It uses the upstream_conf API in NGINX Plus to add the servers registered with Consul and remove the ones which get deregistered without the need for reloading NGINX Plus. This automates the process of upstream reconfiguration in NGINX Plus based on Consul data using a simple bash script and Consul watches.

*   **consul-dns-srv-demo**: This demo shows how to use Consul's DNS interface for load balancing with NGINX Plus. It uses the DNS SRV records using the "service" parameter for the [server](http://nginx.org/en/docs/http/ngx_http_upstream_module.html#server) directive of http upstream module and DNS lookups over TCP feature introduced in NGINX Plus R9. This means that NGINX Plus can now ask for the SRV record (port,weight etc) in the DNS query and also switch the DNS query over TCP automatically if it receives a truncated DNS response over UDP.

*   **coreos-demo**: Shows how to use NGINX Plus to load balance an application running in a CoreOS cluster,
utilizing *fleet* and *etcd*.

*   **etcd-demo**: This demo spins up a bunch of docker containers and shows NGINX Plus being used in conjuction with etcd for service discovery. It uses the upstream_conf API in NGINX Plus to add the servers registered with etcd and remove the ones which get deregistered without the need for reloading NGINX Plus. This automates the process of upstream reconfiguration in NGINX Plus based on etcd data using a simple bash script and 'etcdctl exec-watch'.

*   **gcp-lb-ha-asg**: This demo contains a series of scripts that enable an easy deployment of a High Availability All Active Auto Scaling NGINX Plus Load Balancing configuration on Google Cloud. Adaptation of a guide found [here](https://www.nginx.com/resources/deployment-guides/all-active-nginx-plus-load-balancing-gce/).

*   **mysql-galera-demo**: This demo uses NGINX Plus as a TCP load balancer for a MySQL Galera cluster consisting of two mysqld servers. It does round-robin load balancing between the 2 mysqld servers and also does active health checks using an xinetd script running on port 9200 inside each mysqld container.

*   **nginx-docker-builder**: This demo helps building a docker image to deploy NGINX Plus (privileged and unprivileged), NGINX App Protect WAF and NGINX Agent for NGINX Instance Manager and NGINX One Console

*   **nginx-hello**: NGINX running as webserver in a docker container that serves a simple page containing the container's hostname, IP address and port

*   **nginx-hello-nonroot**: NGINX running as webserver with non root privilege in a docker container that serves a simple page containing the container's hostname, IP address and port

*   **nginx-nms-docker**: This demo helps building a docker image to deploy NGINX Management Suite on containers without Helm. A helper script is provided for Helm deployments

*   **nginx-openstack-heat**: Shows how to deploy and configure NGINX Plus to load balance a simple
web application in OpenStack using Heat. Also the demo shows how NGINX Plus can be reconfigured so that
whenever we create or delete our application instances, NGINX Plus is automatically reconfigured.

*   **nginx-swarm-demo**:  Shows how to use NGINX and NGINX Plus in a Docker Swarm, ultilizing the new features of Docker 1.12.  Demonstrates doing load balancing with just Docker Swarm, then with NGINX open source and then with NGINX Plus, including autoscaling the backend containers.

*   **oauth2-token-introspection-oss**: NGINX OAuth 2.0 Token Introspection (with disk caching)

*   **oauth2-token-introspection-plus**: NGINX Plus OAuth 2.0 Token Introspection (with keyval caching)

*   **random-files**: Demo to show random content and upstream_conf. Nick to add more description here

*   **redis-demo**: This demo uses NGINX Plus as a TCP load balancer for a Redis cluster consisting of 3 Redis nodes in Docker. It does Round-robin load balancing between the 3 Redis nodes, leverages the active health checks feature of NGINX Plus and also shows advanced logging using nginScript.

*   **zookeeper-demo**: This demo spins up a bunch of docker containers and shows NGINX Plus being used in conjuction with Apache Zookeeper for service discovery. It uses the upstream_conf API in NGINX Plus to dynamically add or remove the servers without the need for reloading NGINX Plus. This automates the process of upstream reconfiguration in NGINX Plus based on Zookeeper data using a simple bash script and Zookeeper watches.

* **kubernetes-demo**: Shows how to load balance applications on Kubernetes using NGINX and NGINX Plus.

*   **mqtt-contiki-demo**: Simple MQTT device (mote) for Contiki OS, to demo with Cooji simulator.

Most of the Demos have been configured to utilize Vagrant and Ansible to enable autodeployment.

## Prerequisites for Vagrant/Ansible deploymnets

1. Install Vagrant using the necessary package for your OS:

       https://www.vagrantup.com/downloads.html

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
