# NGINX Instance Manager for Docker

This repository helps deploying NGINX Instance Manager on containerized clusters by creating a docker image.

## Docker image creation

Docker image creation is supported for:

- [NGINX Instance Manager](https://docs.nginx.com/nginx-instance-manager/) 2.4.0+
- [Security Monitoring](https://docs.nginx.com/nginx-management-suite/security/) 1.0.0+
- [NGINX App Protect WAF compiler](https://docs.nginx.com/nginx-management-suite/nim/how-to/app-protect/setup-waf-config-management)

The image can optionally be built with [Second Sight](https://github.com/F5Networks/SecondSight) support

## Tested releases

This repository has been tested on `amd64` and `arm64` architectures with:

- NGINX Instance Manager 2.4.0, 2.5.0, 2.5.1, 2.6.0, 2.7.0, 2.8.0, 2.9.0, 2.9.1, 2.10.0, 2.10.1, 2.11.0, 2.12.0, 2.13.0, 2.13.1, 2.14.0, 2.14.1, 2.15.0, 2.15.1, 2.16.0
- Security Monitoring 1.0.0, 1.1.0, 1.2.0, 1.3.0, 1.4.0, 1.5.0, 1.6.0, 1.7.0, 1.7.1
- NGINX App Protect WAF compiler v3.1088.2, v4.100.1, v4.2.0, v4.218.0, v4.279.0, v4.402.0, v4.457.0, v4.583.0, v4.641, v4.762

## Prerequisites

This repository has been tested with:

- Docker 20.10+ to build the image
- Private registry to push the target Docker image
- Kubernetes cluster with dynamic storage provisioner enabled: see the [example](contrib/pvc-provisioner)
- NGINX Ingress Controller with `VirtualServer` CRD support (see https://docs.nginx.com/nginx-ingress-controller/configuration/virtualserver-and-virtualserverroute-resources/)
- Access to F5/NGINX downloads to fetch NGINX Instance Manager 2.4.0+ installation .deb file (when running in manual mode)
- Valid NGINX license certificate and key to fetch NGINX Instance Manager packages (when running in automated mode)
- Linux host running Docker to build the image

## How to build

The install script can be used to build the Docker image using automated or manual install:

```
$ ./scripts/buildNIM.sh
NGINX Instance Manager Docker image builder

 This tool builds a Docker image to run NGINX Instance Manager

 === Usage:

 ./scripts/buildNIM.sh [options]

 === Options:

 -h                     - This help
 -t [target image]      - Docker image name to be created
 -s                     - Enable Second Sight (https://github.com/F5Networks/SecondSight/) - optional

 Manual build:

 -n [filename]          - NGINX Instance Manager .deb package filename
 -w [filename]          - Security Monitoring .deb package filename - optional
 -p [filename]          - WAF policy compiler .deb package filename - optional

 Automated build:

 -i                     - Automated build - requires cert & key
 -C [file.crt]          - Certificate file to pull packages from the official NGINX repository
 -K [file.key]          - Key file to pull packages from the official NGINX repository
 -W                     - Enable Security Monitoring - optional
 -P [version]           - Enable WAF policy compiler, version can be any [v3.1088.2|v4.100.1|v4.2.0|v4.218.0|v4.279.0|v4.402.0|v4.457.0|v4.583.0] - optional

 === Examples:

 Manual build:
        ./scripts/buildNIM.sh -n nim-files/nms-instance-manager_2.6.0-698150575~focal_amd64.deb \
                -w nim-files/nms-sm_1.0.0-697204659~focal_amd64.deb \
                -p nim-files/nms-nap-compiler-v4.2.0.deb \
                -t my.registry.tld/nginx-nms:2.6.0

 Automated build:
        ./scripts/buildNIM.sh -i -C nginx-repo.crt -K nginx-repo.key
                -W -P v4.583.0 -t my.registry.tld/nginx-nms:latest
```

### Automated build

1. Clone this repo
2. Get your license certificate and key to fetch NGINX Instance Manager packages from NGINX repository
3. Build NGINX Instance Manager Docker image using:

NGINX Instance Manager

```
./scripts/buildNIM.sh -t YOUR_DOCKER_REGISTRY/nginx-nim2:automated -i -C certs/nginx-repo.crt -K certs/nginx-repo.key
```

NGINX Instance Manager, Security Monitoring and WAF Policy Compiler

```
./scripts/buildNIM.sh -t YOUR_DOCKER_REGISTRY/nginx-nim2:automated -i -C certs/nginx-repo.crt -K certs/nginx-repo.key -W -P v4.457.0
```

### Manual build

1. Clone this repository
2. Download NGINX Instance Manager 2.4.0+ .deb installation file for Ubuntu 20.04 and copy it into `nim-files/`
3. Optional: download Security Monitoring .deb installation file for Ubuntu 20.04 and copy it into `nim-files/`
4. Optional: download WAF Policy Compiler .deb installation file for Ubuntu 20.04 and copy it into `nim-files/`
5. Build NGINX Instance Manager Docker image using the provided script

Example:

```
cd nim-files

apt-cache madison nms-instance-manager
apt-get download nms-instance-manager=2.15.1-1175574316~focal

apt-cache madison nms-sm
apt-get download nms-sm=1.7.1-1046510610~focal

apt-cache search nms-nap-compiler
apt-get download nms-nap-compiler-v4.815.0

cd ..

./scripts/buildNIM.sh \
        -t my-private-registry/nginx-instance-manager:2.15.1-nap-v4.815.0-manualbuild \
        -n nim-files/nms-instance-manager_2.15.1-1175574316~focal_amd64.deb \
        -w nim-files/nms-sm_1.7.1-1046510610~focal_amd64.deb \
        -p nim-files/nms-nap-compiler-v4.815.0_4.815.0-1~focal_amd64.deb
```

### Configuring and running

1. Edit `manifests/1.nginx-nim.yaml` and specify the correct image by modifying the "image" line and configure NGINX Instance Manager username, password and the base64-encoded license file for automated license activation.

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
- [Docker compose](contrib/docker-compose)


# Starting NGINX Instance Manager

## On Kubernetes

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

NGINX Instance Manager GUI is now reachable from outside the cluster at:
- Web GUI: `https://nim2.f5.ff.lan`
- gRPC: `nim2.f5.ff.lan:30443`
- Second Sight: see [usage](https://github.com/F5Networks/SecondSight/blob/main/USAGE.md)

## On docker-compose

See [docker-compose](contrib/docker-compose)

# Stopping NGINX Instance Manager

## On Kubernetes

```
$ ./scripts/nimDockerStart.sh stop
namespace "nginx-nim2" deleted
```

## On docker-compose

See [docker-compose](contrib/docker-compose)
