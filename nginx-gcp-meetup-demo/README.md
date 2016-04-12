# GCP Meetup demo

## Prerequisites

1. Linux or OS X machine
1. The following software should be installed on your machine:
  1. Docker
  1. gcloud
  1. make
1. NGINX Plus subscription. You must also have an NGINX Plus license. If you don’t have one, you can sign up for a [free 30-day trial](https://www.nginx.com/#free-trial).
1. Put the licence key and the certificate of your subscription into the ```nginxplus``` folder

## Setup

1. Create a GCE project. Enable Compute Engine API for the project.

1. Authenticate in the gcloud tool:
  ```
  $ gcloud auth
  ```

1. Setup your project and zone:
  ```
  $ gcloud config set project <project-name>
  $ gcloud config set compute/zone us-central1-f
  ```

1. Create a StackDriver account for your project:
  https://console.cloud.google.com/monitoring?project=<project-name>

1. Create the nginxplus instance:
  ```
  $ cd ../nginxplus
  $ ./create-nginxplus-instance.sh
  ```

1. Create the load gen instance:
  ```
  $ cd ../load-generator
  $ ./create-load-generator-instance.sh
  ```

1. Create a kubernetes cluster in Google Compute Engine (GKE)

1. Build the backend Docker image and upload it to the GKE registry

1. Create the backend replication controller

1. Build the knsync Docker image and upload it to the GKE registry

1. Create the knsync rc

1. Build the autoscaler Docker image and upload it to the GKE registry

1. Create the autoscaler controller

1. ssh into the loadgen machine and launch ```load.sh``` few times
