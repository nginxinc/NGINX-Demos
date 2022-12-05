# NGINX Management Suite Helm Installer

This is a bash script to simplify NGINX Management Suite installation through its helm chart.
NGINX Management Suite installation official docs are available at https://docs.nginx.com/nginx-management-suite/admin-guides/installation/helm-chart/

## Usage

Follow these steps:

1. Browse to NGINX Management Suite [Helm Installation Guide](https://docs.nginx.com/nginx-management-suite/admin-guides/installation/helm-chart/)
2. Check the [overview](https://docs.nginx.com/nginx-management-suite/admin-guides/installation/helm-chart/#overview) paragraph
3. Make sure all [prerequisites](https://docs.nginx.com/nginx-management-suite/admin-guides/installation/helm-chart/#before-you-begin) are met
4. Download the [helm bundle](https://docs.nginx.com/nginx-management-suite/admin-guides/installation/helm-chart/#download-helm-bundle)
5. Run the `NGINX-NMS-Installer.sh` script

```
$ ./NGINX-NMS-Installer.sh
NGINX Management Suite Helm Chart installation script

 Usage:

 ./NGINX-NMS-Installer.sh [options]

 Options:

 -h                     - This help

 -i [filename]          - NGINX Management Suite Helm installation file (mandatory)
 -r [registry FQDN]     - Private registry FQDN (mandatory)

 -s [pull secret]       - Private registry pull secret (optional)
 -p [admin password]    - NGINX Management Suite admin password (optional, default is 'admin')
 -n [namespace]         - Destination namespace to install to (optional, default is the current namespace)
 -P [true|false]        - Set persistent volumes usage (optional, default is 'true')

 Example:

 ./NGINX-NMS-Installer.sh -i nms-helm-2.5.1.tar.gz -r myregistry.k8s.local:31005 -s MyPullSecret -p adminP4ssw0rd -n nms-namespace
```

## How to run

```
$ ./NGINX-NMS-Installer.sh -i nms-helm-2.5.1.tar.gz -r registry.ff.lan:31005 -s myPullSecret -p nmsAdminPass -n nms-namespace
NGINX Management Suite Helm Chart installation script

-- Running preflight checks
tar... OK
helm... OK
openssl... OK

-- Installing using:

 Release file:                  nms-helm-2.5.1.tar.gz
 Private registry:              registry.ff.lan:31005
 Private registry pull secret:  myPullSecret
 Destination namespace:         nms-namespace
 Persistent volumes:            true
 Admin password:                nmsAdminPass

Do you want to proceed (YES/no)? YES

-- Processing NMS Helm Chart for release 2.5.1
-- Decompressing nms-helm-2.5.1.tar.gz
.. Importing docker image for nms-apigw-2.5.1.tar.gz
.. Pushing registry.ff.lan:31005/nms-apigw:2.5.1 to private registry
.. Importing docker image for nms-core-2.5.1.tar.gz
.. Pushing registry.ff.lan:31005/nms-core:2.5.1 to private registry
.. Importing docker image for nms-dpm-2.5.1.tar.gz
.. Pushing registry.ff.lan:31005/nms-dpm:2.5.1 to private registry
.. Importing docker image for nms-ingestion-2.5.1.tar.gz
.. Pushing registry.ff.lan:31005/nms-ingestion:2.5.1 to private registry
.. Importing docker image for nms-integrations-2.5.1.tar.gz
.. Pushing registry.ff.lan:31005/nms-integrations:2.5.1 to private registry
-- Decompressing helm chart
-- Running helm install
NAME: nim
LAST DEPLOYED: Tue Oct 25 17:47:23 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

-- Installation complete

Release file:                   nms-helm-2.5.1.tar.gz
 Private registry:              registry.ff.lan:31005
 Private registry pull secret:  myPullSecret
 Destination namespace:         nms-namespace
 Persistent volumes:            true
 Admin password:                nmsAdminPass
```
