# NGINX Docker image builder

## Description

This repository can be used to build a docker image that includes:

- [NGINX Plus](https://docs.nginx.com/nginx) in privileged or unprivileged/non-root mode
- [NGINX Open Source](https://nginx.org/)
- [NGINX App Protect WAF](https://docs.nginx.com/nginx-app-protect-waf)
- [NGINX Agent](https://docs.nginx.com/nginx-agent)

It is also available as part of [official NGINX Demos](https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-agent-docker)

## Tested releases

This repository has been tested with:

- NGINX Plus R29+
- NGINX Opensource 1.24.0+
- NGINX Agent 2.14+
- NGINX Instance Manager 2.15+
- NGINX App Protect WAF 4.100.1+
- NGINX One Cloud Console

## Prerequisites

- Linux host running Docker to build the image
- NGINX Plus license
- Access to either control plane:
  - [NGINX Instance Manager](https://docs.nginx.com/nginx-instance-manager/)
  - [NGINX One Cloud Console](https://docs.nginx.com/nginx-one/)
- Docker/Docker-compose or Openshift/Kubernetes cluster

## Building the docker image

The install script can be used to build the Docker image:

```
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
 -w                     - Add NGINX App Protect WAF (requires NGINX Plus)
 -O                     - Use NGINX Opensource instead of NGINX Plus
 -u                     - Build unprivileged image (only for NGINX Plus)

 === Examples:

 NGINX Plus and NGINX Agent image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:latest -n https://nim.f5.ff.lan

 NGINX Plus, NGINX App Protect WAF and NGINX Agent image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:latest-nap -w -n https://nim.f5.ff.lan

 NGINX Plus, NGINX App Protect WAF and NGINX Agent unprivileged image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:latest-nap -w -n https://nim.f5.ff.lan -u

 NGINX Opensource and NGINX Agent image:
 ./scripts/build.sh -O -t registry.ff.lan:31005/nginx-oss-with-agent:latest -n https://nim.f5.ff.lan
```

1. Clone this repository
2. For NGINX Plus only: get your license certificate and key to fetch NGINX Management Suite packages from NGINX repository
3. [Install](https://docs.nginx.com/nginx-management-suite/) and start NGINX Management Suite / NGINX Instance Manager. Skip this step if using the NGINX SaaS console
4. Build the Docker image using `./scripts/build.sh`

the build script will push the image to your private registry once build is complete.

### Running the docker image on Kubernetes

1. Edit `manifests/1.nginx-nim.yaml` and specify the correct image by modifying the `image:` line, and set the following environment variables. Default values for `NIM_HOST` and `NIM_GRPC_PORT` can be used if NGINX Instance Manager is deployed using https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-nms-docker
  - `NGINX_LICENSE` - NGINX R33+ JWT license token
  - `NIM_HOST` - NGINX Instance Manager hostname/IP address
  - `NIM_GRPC_PORT` - NGINX Instance Manager gRPC port
  - `NIM_TOKEN` - NGINX One Cloud Console authentication token
  - `NIM_INSTANCEGROUP` - instance group for the NGINX instance
  - `NIM_TAGS` - comma separated list of tags for the NGINX instance
  - `NIM_ADVANCED_METRICS` - set to `"true"` to enable advanced metrics collection - NGINX Plus only
  - `NAP_WAF` - set to `"true"` to enable NGINX App Protect WAF (docker image built using `-w`) - NGINX Plus only
  - `NAP_WAF_PRECOMPILED_POLICIES` - set to `"true"` to enable NGINX App Protect WAF precompiled policies (docker image built using `-w`) - NGINX Plus only
  - `AGENT_LOGLEVEL` - NGINX Agent loglevel, optional. If not specified defaults to `info`

2. Start and stop using

```
$ ./scripts/nginxWithAgentStart.sh start
$ ./scripts/nginxWithAgentStart.sh stop
```

3. After startup NGINX instances will register to NGINX Instance Manager / NGINX One console and will be displayed on the "instances" dashboard

### Running the docker image on Docker

1. Start using

```
docker run --rm --name nginx -p [PORT_TO_EXPOSE] \
        -e "NGINX_LICENSE=<NGINX_JWT_LICENSE_TOKEN>" \
        -e "NIM_HOST=<NGINX_CONTROL_PLANE_FQDN_OR_IP>" \
        -e "NIM_GRPC_PORT=<GRPC_PORT>" \
        -e "NIM_TOKEN=<OPTIONAL_AUTHENTICATION_TOKEN>" \
        -e "NIM_INSTANCEGROUP=<OPTIONAL_INSTANCE_GROUP_NAME>" \
        -e "NIM_TAGS=<OPTIONAL_COMMA_DELIMITED_TAG_LIST>" \
        -e "NIM_ADVANCED_METRICS=[true|false]" \
        -e "NAP_WAF=[true|false]" \
        -e "NAP_WAF_PRECOMPILED_POLICIES=[true|false]" \
        -e "AGENT_LOGLEVEL=[panic|fatal|error|info|debug|trace]" \
        <NGINX_DOCKER_IMAGE_NAME:TAG>
```

2. After startup NGINX Plus instances will register to NGINX Instance Manager / NGINX One Console and will be displayed on the "instances" dashboard
