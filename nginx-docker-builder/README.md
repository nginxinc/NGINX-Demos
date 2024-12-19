# NGINX Docker image builder

## Description

This repository can be used to build a docker image that includes:

- [NGINX Plus](https://docs.nginx.com/nginx) in privileged or unprivileged/non-root mode
- [NGINX Open Source](https://nginx.org/)
- [NGINX App Protect WAF](https://docs.nginx.com/nginx-app-protect-waf)
- [NGINX Agent](https://docs.nginx.com/nginx-agent)

## Tested releases

This repository has been tested with:

- [NGINX Plus](https://docs.nginx.com/nginx) R29+
- [NGINX Open Source](https://nginx.org) 1.24.0+
- [NGINX Agent](https://docs.nginx.com/nginx-agent) 2.14+
- [NGINX Instance Manager](https://docs.nginx.com/nginx-instance-manager) 2.15+
- [NGINX App Protect WAF](https://docs.nginx.com/nginx-app-protect-waf) 4.100.1+
- [NGINX One Console](https://docs.nginx.com/nginx-app-protect-waf)

## Prerequisites

- Linux host running Docker to build the image
- NGINX Plus license
- Access to either control plane:
  - [NGINX Instance Manager](https://docs.nginx.com/nginx-instance-manager/)
  - [NGINX One Cloud Console](https://docs.nginx.com/nginx-one/)
- Docker/Docker-compose or Openshift/Kubernetes cluster

## Building the docker image

The `./scripts/build.sh` install script can be used to build the Docker image:

```
NGINX Docker Image builder

 This tool builds a Docker image to run NGINX Plus/Open Source, NGINX App Protect WAF and NGINX Agent

 === Usage:

 ./scripts/build.sh [options]

 === Options:

 -h                     - This help
 -t [target image]      - The Docker image to be created
 -C [file.crt]          - Certificate to pull packages from the official NGINX repository
 -K [file.key]          - Key to pull packages from the official NGINX repository
 -w                     - Add NGINX App Protect WAF (requires NGINX Plus)
 -O                     - Use NGINX Open Source instead of NGINX Plus
 -u                     - Build unprivileged image (only for NGINX Plus)
 -a                     - Add NGINX Agent

 === Examples:

 NGINX Plus and NGINX Agent image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-docker:plus-agent-root -a

 NGINX Plus, NGINX App Protect WAF and NGINX Agent image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-docker:plus-nap-agent-root -w -a

 NGINX Plus, NGINX App Protect WAF and NGINX Agent unprivileged image:
 ./scripts/build.sh -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-docker:plus-nap-agent-nonroot -w -u -a

 NGINX Opensource and NGINX Agent image:
 ./scripts/build.sh -O -t registry.ff.lan:31005/nginx-docker:oss-root -a
```

1. Clone this repository
2. For NGINX Plus only: get your license certificate and key
3. Build the Docker image using `./scripts/build.sh`

### Running the docker image on Kubernetes

1. Edit `manifests/1.nginx-nim.yaml` and specify the correct image by modifying the `image:` line, and set the following environment variables
  - `NGINX_LICENSE` - NGINX R33+ JWT license token
  - `NGINX_AGENT_SERVER_HOST` - NGINX Instance Manager / NGINX One Console hostname/IP address
  - `NGINX_AGENT_SERVER_GRPCPORT` - NGINX Instance Manager / NGINX One Console gRPC port
  - `NGINX_AGENT_SERVER_TOKEN` - NGINX Instance Manager / NGINX One Console authentication token
  - `NGINX_AGENT_INSTANCE_GROUP` - instance group (NGINX Instance Manager) / config sync group (NGINX One Console) for the NGINX instance
  - `NGINX_AGENT_TAGS` - comma separated list of tags for the NGINX instance
  - `NAP_WAF` - set to `"true"` to enable NGINX App Protect WAF (docker image built using `-w`) - NGINX Plus only
  - `NAP_WAF_PRECOMPILED_POLICIES` - set to `"true"` to enable NGINX App Protect WAF precompiled policies (docker image built using `-w`) - NGINX Plus only
  - `NGINX_AGENT_LOG_LEVEL` - NGINX Agent loglevel, optional. If not specified defaults to `info`

2. Deploy on Kubernetes using the example manifest `manifest/nginx-manifest.yaml`

3. After startup the NGINX instance will register to NGINX Instance Manager / NGINX One console and will be displayed on the "instances" dashboard if the NGINX Agent has been build into the docker image

### Running the docker image on Docker

1. Start using

```
docker run --rm --name nginx -p [PORT_TO_EXPOSE] \
        -e "NGINX_LICENSE=<NGINX_JWT_LICENSE_TOKEN>" \
        -e "NGINX_AGENT_SERVER_HOST=<NGINX_INSTANCE_MANAGER_OR_NGINX_ONE_CONSOLE_FQDN_OR_IP>" \
        -e "NGINX_AGENT_SERVER_GRPCPORT=<NGINX_INSTANCE_MANAGER_OR_NGINX_ONE_CONSOLE_GRPC_PORT>" \
        -e "NGINX_AGENT_SERVER_TOKEN=<NGINX_INSTANCE_MANAGER_OR_NGINX_ONE_CONSOLE_OPTIONAL_AUTHENTICATION_TOKEN>" \
        -e "NGINX_AGENT_INSTANCE_GROUP=<NGINX_INSTANCE_MANAGER_OR_NGINX_ONE_CONSOLE_OPTIONAL_INSTANCE_GROUP_OR_CONFIG_SYNC_GROUP_NAME>" \
        -e "NGINX_AGENT_TAGS=<OPTIONAL_COMMA_DELIMITED_TAG_LIST>" \
        -e "NAP_WAF=[true|false]" \
        -e "NAP_WAF_PRECOMPILED_POLICIES=[true|false]" \
        -e "NGINX_AGENT_LOG_LEVEL=[panic|fatal|error|info|debug|trace]" \
        <NGINX_DOCKER_IMAGE_NAME:TAG>
```

2. After startup the NGINX instance will register to NGINX Instance Manager / NGINX One Console and will be displayed on the "instances" dashboard if the NGINX Agent has been build into the docker image
