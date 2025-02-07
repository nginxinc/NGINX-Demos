#!/bin/bash

BANNER="NGINX Instance Manager Docker image builder\n\n
This tool builds a Docker image to run NGINX Instance Manager\n\n
=== Usage:\n\n
$0 [options]\n\n
=== Options:\n\n
-h\t\t\t- This help\n
-t [target image]\t- Docker image name to be created\n\n
Manual build:\n\n
-n [filename]\t\t- NGINX Instance Manager .deb package filename\n
-w [filename]\t\t- Security Monitoring .deb package filename - optional\n
-p [filename]\t\t- WAF policy compiler .deb package filename - optional\n\n
Automated build:\n\n
-i\t\t\t- Automated build - requires cert & key\n
-C [file.crt]\t\t- Certificate file to pull packages from the official NGINX repository\n
-K [file.key]\t\t- Key file to pull packages from the official NGINX repository\n
-P [version]\t\t- Enable WAF policy compiler, version can be any [v3.1088.2|v4.100.1|v4.2.0|v4.218.0|v4.279.0|v4.402.0|v4.457.0|v4.583.0|v4.641|v4.762|v4.815.0|v5.17.0|v5.48.0|v5.144.0] - optional\n\n
=== Examples:\n\n
Manual build:\n
\t$0 -t my-private-registry/nginx-instance-manager:2.15.1-nap-v4.815.0-manualbuild \\\\\\n
\t\t-n nim-files/nms-instance-manager_2.15.1-1175574316~focal_amd64.deb \\\\\n
\t\t-w nim-files/nms-sm_1.7.1-1046510610~focal_amd64.deb \\\\\n
\t\t-p nim-files/nms-nap-compiler-v4.815.0_4.815.0-1~focal_amd64.deb\n\n
Automated build:\n
\t$0 -i -C nginx-repo.crt -K nginx-repo.key \\\\\n
\t\t-P v5.144.0 -t my.registry.tld/nginx-nms:latest\n
"

while getopts 'hn:w:p:t:siC:K:AP:' OPTION
do
	case "$OPTION" in
		h)
			echo -e $BANNER
			exit
		;;
		n)
			DEBFILE=$OPTARG
		;;
		w)
			SM_IMAGE=$OPTARG
		;;
		p)
			PUM_IMAGE=$OPTARG
		;;
		t)
			IMGNAME=$OPTARG
		;;
		i)
			AUTOMATED_INSTALL=true
		;;
		C)
			NGINX_CERT=$OPTARG
		;;
		K)
			NGINX_KEY=$OPTARG
		;;
                P)
                        ADD_PUM=$OPTARG
                ;;
	esac
done

if [ -z "$1" ]
then
	echo -e $BANNER
	exit
fi

if [ -z "${IMGNAME}" ]
then
	echo "Docker image name is required"
	exit
fi

if ([ -z "${AUTOMATED_INSTALL}" ] && [ -z "${DEBFILE}" ])
then
	echo "NGINX Instance Manager package is required for manual installation"
	exit
fi

if ([ ! -z "${AUTOMATED_INSTALL}" ] && ([ -z "${NGINX_CERT}" ] || [ -z "${NGINX_KEY}" ]))
then
	echo "NGINX certificate and key are required for automated installation"
        exit
fi

echo "==> Building NGINX Management Suite docker image"

if [ -z "${AUTOMATED_INSTALL}" ]
then
        docker build --no-cache -f Dockerfile.manual --build-arg NIM_DEBFILE=$DEBFILE \
                --build-arg SM_IMAGE=$SM_IMAGE --build-arg PUM_IMAGE=$PUM_IMAGE -t $IMGNAME .
else
	DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.automated --secret id=nginx-key,src=$NGINX_KEY --secret id=nginx-crt,src=$NGINX_CERT \
                --build-arg ADD_PUM=$ADD_PUM \
                -t $IMGNAME .
fi

docker push $IMGNAME
