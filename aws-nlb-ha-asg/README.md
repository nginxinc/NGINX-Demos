# All Active Auto Scaling AWS NLB NGINX Plus Demo Environment

## Overview

This set of Packer and Terraform scripts create an all active auto scaling AWS NLB NGINX demo environment. An AWS NLB is used to load balance inconming traffic to an auto scaling NGINX Plus group, which in turn load balance the traffic to two distinct auto scaling NGINX Open Source web server instances.

### Packer

[Packer](https://www.packer.io/) is a tool developed by Hashicorp to automate the creation of any type of machine/golden images in a variety of infrastructure providers. It follows an Infrastructure as Code design pattern that allows developers to write a simple json file describing the target machine image.

In this implementation, Packer is used to create an AWS NGINX Plus AMI and an AWS open source NGINX AMI.

### Terraform

[Terraform](https://www.terraform.io/) is a tool developed by Hashicorp to write, plan, and create infrastructure on a variety of infrastructure providers. It follows an Infrastructure as Code design pattern that allows developers to write a simple Terraform configuration file describing the target infrastructure details.

In this implementation, Terraform is used to create a set of AWS EC2 instances and configure NGINX as necessary using AWS EC2 user-data. Additionally, a new set of networking rules and security group settings are created to avoid conflicts with any pre-existing network settings.

## Prerequisites and Required AWS configuration

The instructions assume you have the following:

*   An AWS account.
*   An NGINX Plus subscription.
*   Familiarity with NGINX configuration syntax.

## Setup

1.  [Install](https://www.packer.io/intro/getting-started/install.html) Packer.
    *   The minimum version of Packer required is **Packer v1.5.0** and as such might not work if a different version of Packer is employed. We will strive to update the code if any breaking changes are introduced in a future release of Packer.
2.  [Install](https://www.terraform.io/intro/getting-started/install.html) Terraform.
    *   The minimum version of Terraform required is **Terraform v0.12.0** and as such might not work if a different version of Terraform is employed. We will strive to update the code if any breaking changes are introduced in a future release of Terraform.
3.  Set your AWS credentials in the Packer and Terraform scripts:

    1.  For Packer, set your credentials in the variables block in `packer/packer.json`:
    ```
    "variables": {
      "home": "{{env `HOME`}}",
      "aws_access_key": "",
      "aws_secret_key": ""
    }
    ```
    2.  For Terraform, set your credentials in `terraform/provider.tf`:
    ```
    provider "aws" {
      region = "us-west-1"
      access_key = ""
      secret_key = ""
    }
    ```
4.  Copy your NGINX Plus certificate and key into `~/.ssh/ngx-certs`.
5.  Run `./setup.sh`.
6.  Once you're done playing with the demo, delete everything by running `./cleanup.sh`.
