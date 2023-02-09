# Ansible Playbook to Manage NGINX Plus Instances via NGINX Management Suite (NMS)

This is an example playbook to get a total number of NGINX Plus instances and to meet the requirement of having NGINX Plus managed by NMS. The playbooks will do the following:
* *nms-agent-install.yml*
  * Install NMS on separate host
  * Install NGINX Agent on NGINX Plus instances
* *nms-agent-upgrade.yml*
  * Upgrade NMS if available
  * Upgrade NGINX Agent if available

## Prerequisites

1. Separate Host for NMS
1. Install Required Ansible Collection and Roles

### Separate Host for NMS

This playbook requires a separate host for NMS installation. Take a look at [NMS Supported Distributions](https://docs.nginx.com/nginx-management-suite/overview/tech-specs/#supported-distributions).

### Install Required Ansible Collection and Roles 

This playbook depends on the following roles and collections below so be sure to install these via `ansible-galaxy`.
1. [NGINX Management Suite Ansible Role](https://github.com/nginxinc/ansible-role-nginx-management-suite)
2. [NGINX Ansible Role](https://github.com/nginxinc/ansible-role-nginx)
3. [NGINX Management Suite Collection](https://github.com/TuxInvader/ansible_collection_nginx_management_suite)

## Usage

### Installing Collection and Roles

An example of installing these can be ran by using the following commands.
```shell
ansible-galaxy install -r requirement.yml
ansible-galaxy collection install -r requirement.collection.yaml
```

### Create Inventory File

Look at the `inventory.sample` file for a sample but defining the the hosts.

### Install NMS and NGINX Agent

Run the following command to start the playbook to install NMS and NGINX Agents on your NGINX Plus instances.

```shell
ansible-playbook -i inventory.sample nms-agent-install.yml
```

### Update NMS and NGINX Agent

It is a good idea to keep NMS and NGINX Agent up to date. Below is an example playbook that will update NMS and NGINX Agent.

```shell
ansible-playbook -i inventory.sample nms-agent-upgrade.yml
```
