# Misc NGINX Demos from conferences showing different functionality of NGINX and NGINX Plus

* **autoscaling-demo**: This demo uses one NGINX Plus instance as a load balancer with two upstream groups, one for NGINX Plus web servers and one for Elasticsearch nodes.  All of the instances run in Docker containers. The demo uses both the upstream_conf and status api's.  If shows creating a new NGINX Plus environment and adding and removing containers manually and with autoscaling.

* **consul-demo**: This demo shows NGINX Plus being used in conjuction with Consul, a service discovery platform. This demo is based on docker.

* **random-files**: 

All of the Demos have been configured to utilize Vagrant and Ansible to enable autodeployment.

## Prerequisites for Vagrant/Ansible deploymnets

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