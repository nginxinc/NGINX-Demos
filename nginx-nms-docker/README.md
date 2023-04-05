# NGINX Management Suite for Docker

This repository helps deploying NGINX Management Suite on containerized clusters by creating a docker image or deploying the official Helm chart with a simple bash script.

## Docker image creation

Docker image creation is supported for:

- [NGINX Instance Manager](https://docs.nginx.com/nginx-instance-manager/) 2.4.0+
- [NGINX Management Suite API Connectivity Manager](https://docs.nginx.com/nginx-management-suite/acm/) 1.0.0+
- [Security Monitoring](https://docs.nginx.com/nginx-management-suite/admin-guides/installation/install-guide/#install-nms-modules) 1.0.0+
- [NGINX App Protect WAF compiler](https://docs.nginx.com/nginx-management-suite/nim/how-to/app-protect/setup-waf-config-management)

The image can optionally be built with [Second Sight](https://github.com/F5Networks/SecondSight) support


## Deployment through the official Helm chart

A bash script to quickly install NGINX Management Suite through the official Helm chart is available here:

- [Helm installer](contrib/helm-installer)

## Tested releases

This repository has been tested with:

- NGINX Instance Manager 2.4.0, 2.5.0, 2.5.1, 2.6.0, 2.7.0, 2.8.0, 2.9.0
- NGINX Management Suite API Connectivity Manager 1.0.0, 1.1.0, 1.1.1, 1.2.0, 1.3.0, 1.3.1, 1.4.0, 1.4.1, 1.5.0
- Security Monitoring 1.0.0, 1.1.0, 1.2.0, 1.3.0
- NGINX App Protect WAF compiler 3.1088.2, 4.2.0, 4.100.1, 4.218.0

## Prerequisites

- Docker 20.10+ to build the image
- Private registry to push the target Docker image
- Kubernetes/Openshift cluster with dynamic storage provisioner enabled: see the [example](contrib/pvc-provisioner)
- NGINX Ingress Controller with `VirtualServer` CRD support (see https://docs.nginx.com/nginx-ingress-controller/configuration/virtualserver-and-virtualserverroute-resources/)
- Access to F5/NGINX downloads to fetch NGINX Instance Manager 2.4.0+ installation .deb file and API Connectivity Manager 1.0+ installation .deb file (when running in manual mode)
- Valid NGINX license certificate and key to fetch NGINX Management Suite packages (when running in automated mode)
- Linux host running Docker to build the image

## How to build

The install script can be used to build the Docker image using automated or manual install:

```
$ ./scripts/buildNIM.sh 
NGINX Management Suite Docker image builder

 This tool builds a Docker image to run NGINX Management Suite

 === Usage:

 ./scripts/buildNIM.sh [options]

 === Options:

 -h                     - This help
 -t [target image]      - Docker image name to be created
 -s                     - Enable Second Sight (https://github.com/F5Networks/SecondSight/) - optional

 Manual build:

 -n [filename]          - NGINX Instance Manager .deb package filename
 -a [filename]          - API Connectivity Manager .deb package filename - optional
 -w [filename]          - Security Monitoring .deb package filename - optional
 -p [filename]          - WAF policy compiler .deb package filename - optional

 Automated build:

 -i                     - Automated build - requires cert & key
 -C [file.crt]          - Certificate file to pull packages from the official NGINX repository
 -K [file.key]          - Key file to pull packages from the official NGINX repository
 -A                     - Enable API Connectivity Manager - optional
 -W                     - Enable Security Monitoring - optional
 -P [version]           - Enable WAF policy compiler, version can be [v3.1088.2|v4.2.0|v4.100.1|v4.218.0] - optional

 === Examples:

 Manual build:
        ./scripts/buildNIM.sh -n nim-files/nms-instance-manager_2.6.0-698150575~focal_amd64.deb \
                -a nim-files/nms-api-connectivity-manager_1.2.0.668430332~focal_amd64.deb \
                -w nim-files/nms-sm_1.0.0-697204659~focal_amd64.deb \
                -p nim-files/nms-nap-compiler-v4.2.0.deb \
                -t my.registry.tld/nginx-nms:2.6.0

 Automated build:
        ./scripts/buildNIM.sh -i -C nginx-repo.crt -K nginx-repo.key
                -A -W -P v4.218.0 -t my.registry.tld/nginx-nms:2.9.0
```

### Automated build

1. Clone this repo
2. Get your license certificate and key to fetch NGINX Management Suite packages from NGINX repository
3. Build NGINX Instance Manager Docker image using:

NGINX Instance Manager

```
./scripts/buildNIM.sh -t registry.ff.lan:31005/nginx-nim2:automated -i -C certs/nginx-repo.crt -K certs/nginx-repo.key
```

NGINX Instance Manager and API Connectivity Manager

```
./scripts/buildNIM.sh -t registry.ff.lan:31005/nginx-nim2:automated -i -C certs/nginx-repo.crt -K certs/nginx-repo.key -A
```

NGINX Instance Manager, Security Monitoring and WAF Policy Compiler

```
./scripts/buildNIM.sh -t registry.ff.lan:31005/nginx-nim2:automated -i -C certs/nginx-repo.crt -K certs/nginx-repo.key -W -P v4.2.0
```

NGINX Instance Manager, API Connectivity Manager, WAF Policy Compiler and Security Monitoring

```
./scripts/buildNIM.sh -t registry.ff.lan:31005/nginx-nim2:automated -i -C certs/nginx-repo.crt -K certs/nginx-repo.key -A -W -P v4.2.0
```

### Manual build

1. Clone this repo
2. Download NGINX Instance Manager 2.4.0+ .deb installation file for Ubuntu 20.04 and copy it into `nim-files/`
3. Optional: download API Connectivity Manager 1.0+ .deb installation file for Ubuntu 20.04 and copy it into `nim-files/`
4. Optional: download Security Monitoring .deb installation file for Ubuntu 20.04 and copy it into `nim-files/`
5. Optional: download WAF Policy Compiler .deb installation file for Ubuntu 20.04 and copy it into `nim-files/`
6. Build NGINX Instance Manager Docker image using:

```
./scripts/buildNIM.sh -n nim-files/nms-instance-manager_2.6.0-698150575~focal_amd64.deb \
        -a nim-files/nms-api-connectivity-manager_1.2.0.668430332~focal_amd64.deb \
        -w nim-files/nms-sm_1.0.0-697204659~focal_amd64.deb \
        -p nim-files/nms-nap-compiler-v4.2.0_4.2.0-1~focal_amd64.deb \
        -t my.registry.tld/nginx-nms:2.6.0
```

### Configuring and running

1. Edit `manifests/1.nginx-nim.yaml` and specify the correct image by modifying the "image" line and configure NGINX Instance Manager username, password and the base64-encoded license file for automated license activation. In order to use API Connectivity Manager an ACM license is required

```
image: your.registry.tld/nginx-nim2:tag
[...]
env:
  ### NGINX Instance Manager environment
  - name: NIM_USERNAME
    value: admin
  - name: NIM_PASSWORD
    value: nimadmin
  - name: NIM_LICENSE
    value: "<BASE64_ENCODED_LICENSE_FILE>"
```

To base64-encode the license file the following command can be used:

```
base64 -w0 NIM_LICENSE_FILENAME.lic
```

Additionally, parameters user by NGINX Instance Manager to connect to ClickHouse can be configured:

```
env:
  [...]
  - name: NIM_CLICKHOUSE_ADDRESS
    value: clickhouse
  - name: NIM_CLICKHOUSE_PORT
    value: "9000"
  ### If username is not set to "default", the clickhouse-users ConfigMap in 0.clickhouse.yaml shall be updated accordingly
  - name: NIM_CLICKHOUSE_USERNAME
    value: "default"
  ### If password is not set to "NGINXr0cks", the clickhouse-users ConfigMap in 0.clickhouse.yaml shall be updated accordingly
  - name: NIM_CLICKHOUSE_PASSWORD
    value: "NGINXr0cks"
```

2. If Second Sight was built in the image, configure the relevant environment variables. See the documentation at https://github.com/F5Networks/SecondSight/#on-kubernetesopenshift

```
env:
  ### Second Sight Push mode
  - name: STATS_PUSH_ENABLE
    #value: "true"
    value: "false"
  - name: STATS_PUSH_MODE
    value: CUSTOM
    #value: PUSHGATEWAY
  - name: STATS_PUSH_URL
    value: "http://192.168.1.5/callHome"
    #value: "http://pushgateway.nginx.ff.lan"
  ### Push interval in seconds
  - name: STATS_PUSH_INTERVAL
    value: "10"
```

3. Check / modify files in `/manifests/certs` to customize the TLS certificate and key used for TLS offload

4. Start and stop using

```
./scripts/nimDockerStart.sh start
./scripts/nimDockerStart.sh stop
```

5. After starting NGINX Instance Manager it will be accessible from outside the cluster at:

NGINX Instance Manager GUI: `https://nim2.f5.ff.lan`
NGINX Instance Manager gRPC port: `nim2.f5.ff.lan:30443`

and from inside the cluster at:

NGINX Instance Manager GUI: `https://nginx-nim2.nginx-nim2`
NGINX Instance Manager gRPC port: `nginx-nim2.nginx-nim2:443`


Second Sight REST API (if enabled at build time - see the documentation at `https://github.com/F5Networks/SecondSight`):
- `https://nim2.f5.ff.lan/f5tt/instances`
- `https://nim2.f5.ff.lan/f5tt/metrics`
- Push mode (configured through env variables in `manifests/1.nginx-nim.yaml`)

Grafana dashboard: `https://grafana.nim2.f5.ff.lan` - see [configuration details](contrib/grafana)

Running pods are:

```
$ kubectl get pods -n nginx-nim2 -o wide
NAME                          READY   STATUS    RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
clickhouse-7bc96d6d56-jthtf   1/1     Running   0          5m8s   10.244.1.65   f5-node1   <none>           <none>
grafana-6f58d455c7-8lk64      1/1     Running   0          5m8s   10.244.2.80   f5-node2   <none>           <none>
nginx-nim2-679987c54d-7rl6b   1/1     Running   0          5m8s   10.244.1.64   f5-node1   <none>           <none>
```

6. For NGINX Instances running on VM/bare metal only: after installing the nginx-agent on NGINX Instances to be managed with NGINX Instance Manager 2, update the file `/etc/nginx-agent/nginx-agent.conf` and modify the line:

```
grpcPort: 443
```

into:

```
grpcPort: 30443
```

and then restart nginx-agent


## Additional tools

- [Grafana dashboard for telemetry](contrib/grafana)
- [Helm installer](contrib/helm-installer)


# Starting NGINX Management Suite

```
$ ./scripts/nimDockerStart.sh start
namespace/nginx-nim2 created
Generating a RSA private key
...................+++++
...............................+++++
writing new private key to 'nim2.f5.ff.lan.key'
-----
secret/nim2.f5.ff.lan created
deployment.apps/nginx-nim2 created
service/nginx-nim2 created
service/nginx-nim2-grpc created 
virtualserver.k8s.nginx.org/vs-nim2 created

$ kubectl get pods -n nginx-nim2 -o wide
NAME                          READY   STATUS    RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
clickhouse-7bc96d6d56-jthtf   1/1     Running   0          5m8s   10.244.1.65   f5-node1   <none>           <none>
grafana-6f58d455c7-8lk64      1/1     Running   0          5m8s   10.244.2.80   f5-node2   <none>           <none>
nginx-nim2-679987c54d-7rl6b   1/1     Running   0          5m8s   10.244.1.64   f5-node1   <none>           <none>
```

NGINX Management Suite GUI is now reachable from outside the cluster at:
- Web GUI: `https://nim2.f5.ff.lan`
- gRPC: `nim2.f5.ff.lan:30443`
- Second Sight: see [usage](https://github.com/F5Networks/SecondSight/blob/main/USAGE.md)

# Stopping NGINX Management Suite

```
$ ./scripts/nimDockerStart.sh stop
namespace "nginx-nim2" deleted
```
