# NGINX Plus and NGINX Agent - Docker image builder

## Description

This repository can be used to build a docker image with NGINX Plus and NGINX Instance Manager Agent (https://docs.nginx.com/nginx-instance-manager/).

## Tested releases

This repository has been tested with NGINX agent for:

- NGINX Instance Manager 2.4.0, 2.5.0, 2.5.1, 2.6.0, 2.7.0, 2.8.0, 2.9.0, 2.10.0, 2.10.1, 2.11.0, 2.12.0, 2.13.0, 2.13.1, 2.14.0, 2.14.1, 2.15.0
- NGINX App Protect WAF 4.100.1+

## Prerequisites

- Linux host running Docker to build the image
- NGINX Plus license
- A running [NGINX Instance Manager](https://docs.nginx.com/nginx-instance-manager/) instance
- [API Connectivity Manager](https://docs.nginx.com/nginx-management-suite/acm/about/architecture/) if building with support for Developer Portal
- Openshift/Kubernetes cluster

## Building the docker image

The install script can be used to build the Docker image:

```
$ ./scripts/build.sh 
NGINX Plus & NGINX Instance Manager agent Docker image builder

 This tool builds a Docker image to run NGINX Plus and NGINX Instance Manager agent

 === Usage:

 ./scripts/build.sh [options]

 === Options:

 -h                     - This help
 -t [target image]      - The Docker image to be created
 -C [file.crt]          - Certificate to pull packages from the official NGINX repository
 -K [file.key]          - Key to pull packages from the official NGINX repository
 -n [URL]               - NGINX Instance Manager URL to fetch the agent
 -w                     - Add NGINX App Protect WAF

 === Examples:

 NGINX Plus and NGINX Agent image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:latest -n https://nim.f5.ff.lan

 NGINX Plus, NGINX App Protect WAF and NGINX Agent image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:latest-nap -w -n https://nim.f5.ff.lan
```

1. Clone this repository
2. Get your license certificate and key to fetch NGINX Management Suite packages from NGINX repository
3. [Install](https://docs.nginx.com/nginx-management-suite/) and start NGINX Management Suite / NGINX Instance Manager
4. Build the Docker image using:

```
$ ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:r28 -n https://ubuntu.ff.lan
```

the build script will push the image to your private registry once build is complete.

- the `-w` flag can be used to include NGINX App Protect WAF support in the docker image

### Running the docker image on Kubernetes

1. Edit `manifests/1.nginx-nim.yaml` and specify the correct image by modifying the `image:` line, and set the following environment variables. Default values for `NIM_HOST` and `NIM_GRPC_PORT` can be used if NGINX Instance Manager is deployed using https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-nms-docker
  - `NIM_HOST` - NGINX Instance Manager hostname/IP address
  - `NIM_GRPC_PORT` - NGINX Instance Manager gRPC port.
  - `NIM_INSTANCEGROUP` - instance group for the NGINX instance
  - `NIM_TAGS` - comma separated list of tags for the NGINX instance
  - `NIM_ADVANCED_METRICS` - set to `"true"` to enable advanced metrics collection
  - `NAP_WAF` - set to `"true"` to enable NGINX App Protect WAF (docker image built using `-w`)
  - `NAP_WAF_PRECOMPILED_POLICIES` - set to `"true"` to enable NGINX App Protect WAF precompiled policies (docker image built using `-w`)

2. Start and stop using

```
$ ./scripts/nginxWithAgentStart.sh start
$ ./scripts/nginxWithAgentStart.sh stop
```

3. After startup NGINX Plus instances will register to NGINX Instance Manager and will be displayed on the "instances" dashboard

### Running the docker image on Docker

1. Start using

```
NGINX Plus and NGINX Agent
docker run --name nginx-plus -d -e "NIM_HOST=<NIM_FQDN_OR_IP>" -e "NIM_GRPC_PORT=<GPRC_PORT>" -d registry.ff.lan:31005/nginx-with-agent:latest

NGINX Plus, NGINX Agent and NGINX App Protect WAF with precompiled policies
docker run --name nginx-plus -d -e "NIM_HOST=<NIM_FQDN_OR_IP>" -e "NIM_GRPC_PORT=<GPRC_PORT>" -e "NAP_WAF=true" -e "NAP_WAF_PRECOMPILED_POLICIES=true" -d registry.ff.lan:31005/nginx-with-agent:latest-nap
```

2. After startup NGINX Plus instances will register to NGINX Instance Manager and will be displayed on the "instances" dashboard
