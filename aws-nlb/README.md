# Initial AWS NLB NGINX setup on AWS using Packer and Terraform

## Overview

This set of Packer and Terraform scripts create a simple setup with two NGINX Plus load balancer instances and four open source NGINX web server instances. The open source NGINX web server instances represent two distinct websites, with each NGINX Plus instance load balancing between the two instances of each open source NGINX website as necessary. This simple setup allows to easily add a NLB in front of the two NGINX Plus load balancer instances.

### Packer

[Packer](https://www.packer.io/) is a tool developed by Hashicorp to automate the creation of any type of machine/golden images in a variety of infrastructure providers. It follows an Infrastructure as Code design pattern that allows developers to write a simple json file describing the target machine image.

In this implementation, Packer is used to create an AWS NGINX Plus AMI and an AWS open source NGINX AMI.

### Terraform

[Terraform](https://www.terraform.io/) is a tool developed by Hashicorp to write, plan, and create infrastructure on a variety of infrastructure providers. It follows an Infrastructure as Code design pattern that allows developers to write a simple Terraform configuration file describing the target infrastructure details.

In this implementation, Terraform is used to create a set of AWS EC2 instances and configure NGINX as necessary using AWS EC2 user-data. Additionally, a new set of networking rules and security group settings are created to avoid conflicts with any pre-existing network settings.

## Prerequisites and Required AWS configuration

The instructions assume you have the following:

* An AWS account.
* An NGINX Plus subscription.
* Familiarity with NGINX configuration syntax.

## Setup

1. [Install](https://www.packer.io/intro/getting-started/install.html) Packer.
    * This solution was developed using **Packer v1.0.4** and as such might not work if a different version of Packer is employed. We will strive to update the code if any breaking changes are introduced in a future release of Packer.
2. [Install](https://www.terraform.io/intro/getting-started/install.html) Terraform.
    * This solution was developed using **Terraform v0.10.8** and as such might not work if a different version of Terraform is employed. We will strive to update the code if any breaking changes are introduced in a future release of Terraform.
3. Set your AWS credentials in the Packer and Terraform scripts:

    1. For Packer, set your credentials in the variables block in `packer/ngx-oss/packer.json` and `packer/ngx-plus/packer.json`:
    ```
    "variables": {
      "home": "{{env `HOME`}}",
      "aws_access_key": "",
      "aws_secret_key": ""
    }
    ```
    2. For Terraform, set your credentials in `terraform/provider.tf`:
    ```
    provider "aws" {
      region = "us-west-1"
      access_key = ""
      secret_key = ""
    }
    ```
4. Copy your NGINX Plus certificate and key into `~/.ssh/certs`.
5. Run `./setup.sh` (you may need to make the script executable beforehand by using `chmod +x setup.sh`).
