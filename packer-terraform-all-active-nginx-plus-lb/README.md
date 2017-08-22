# All Active Nginx Plus Load Balancing on Google Compute Engine (GCE) using Packer and Terraform

## Overview

This set of Packer and Terraform scripts enable an easy deployment of a High Availability All Active Auto Scaling NGINX Plus Load Balancing configuration on Google Cloud. Adaptation of a guide found [here](https://www.nginx.com/resources/deployment-guides/all-active-nginx-plus-load-balancing-gce/).

### Packer

[Packer](https://www.packer.io/) is a tool developed by Hashicorp to automate the creation of any type of machine/golden images in a variety of infrastructure providers. It follows an Infrastructure as Code design pattern that allows developers to write a simple json file describing the target machine image.

In this implementation, Packer is used to create a Google Cloud NGINX Plus image configured to work as a Load Balancer (**nginx-plus-lb-image**) and two distinct Google Cloud NGINX Plus images configured to work as application web servers  (**nginx-plus-app-1-image** & **nginx-plus-app-2-image**).

### Terraform

[Terraform](https://www.terraform.io/) is a tool developed by Hashicorp to write, plan, and create infrastructure on a variety of infrastructure providers. It follows an Infrastructure as Code design pattern that allows developers to write a simple Terraform configuration file describing the target infrastructure details.

In this implementation, Terraform is used to create a set of Google Cloud instance templates and instance group managers using the images previously created with Packer that can autoscale and recover in case of an unexpected instance crash. A set of networking rules are also defined to allow clients to access the instances via a static external IP or via the dynamic IPs created on instance startup.

## Setup

1. [Install](https://www.packer.io/intro/getting-started/install.html) Packer.
    * This solution was developed using **Packer v1.0.4** and as such might not work if a different version of Packer is employed. We will strive to update the code if any breaking changes are introduced in a future release of Packer.
2. [Install](https://www.terraform.io/intro/getting-started/install.html) Terraform.
    * This solution was developed using **Terraform v0.10.2** and as such might not work if a different version of Terraform is employed. We will strive to update the code if any breaking changes are introduced in a future release of Terraform.
3. [Create](https://cloud.google.com/) a Google Cloud account.
4. [Create](https://cloud.google.com/resource-manager/docs/creating-managing-projects) a Google Cloud project.
5. [Download](https://www.terraform.io/docs/providers/google/index.html) the corresponding credentials for the previously created project. Terraform has a good [guide](https://www.terraform.io/docs/providers/google/index.html) on how to do this. You will need to wait until the Compute Engine has initialized before you are able to download the default account credentials. Copy and rename the credentials to `~/.gcloud/gcloud_credentials.json`.
6. [Install](https://cloud.google.com/sdk/downloads) the Google Cloud SDK.
7. [Install](https://cloud.google.com/sdk/docs/managing-components) the Google Cloud SDK beta commands.
8. [Clone or download](https://github.com/nginxinc/NGINX-Demos/tree/master/packer-terraform-all-active-nginx-plus-lb) the files in the Packer Terraform All Active Nginx Plus LB folder in the NGINX Demos GitHub repo.
9. Change the variables in `variables.tf` and `packer.json` to include your project id, the region/zone of your project, the desired machine type for your instances, and the Gcloud credentials file path.
10. Copy your NGINX Plus crt and key into the `packer/certs` subfolder.
11. Open a terminal, navigate to the location where you cloned the repository, and run `./setup.sh`.
12. To test the autoscaling features, install [wrk](https://github.com/wg/wrk) and run `wrk -t12 -c400 -d30s http://$static_external_ip` where `$static_external_ip` is the output of the Terraform script.
13. If you want to see a nice graph representation of the Terraform dependencies install the [Graphviz software](http://www.graphviz.org/) and run `terraform graph | dot -Tpng > graph.png`.
14. Once you're done with the demo and/or you want to delete the Google Cloud environment you've just created run `./cleanup.sh`.

## Code Structure

### Packer

The whole Packer configuration is included in the `packer.json` file in the `packer` folder. It is structured in three distinct sections.

1. `variables`: This sections defines variables that are employed throughout the `packer.json` file such as the project id or project region.
2. `builders`: This section describes the target images to be built by packer. One LB image and two web servers images in this case.
3. `provisioners`: This section comprises the bulk of the `packer.json` file. It is here that the steps required to build each machine image are included.

### Terraform

The Terraform configuration is split into various `*.tf` files in the `terraform` folder. Each file is responsible for a distinct functionality.

* `autoscaler.tf`: Creates and setups Google Cloud autoscalers.
* `healthcheck.tf`: Creates and setups Google Cloud healthchecks.
* `instance.tf`: Creates and setups the Google Cloud Engine instances used to deploy the machine images previously created by Packer.
* `network.tf`: Creates and setups the Google Cloud firewall, forwarding rules and external static IP addresses.
* `output.tf`: Outputs the external static IP addresses to the terminal.
* `providers.tf`: Defines the parameters required to establish and authenticate a connection with Google Cloud.
* `variables.tf`: Defines various variables used throughout the rest of the Terraform files.
