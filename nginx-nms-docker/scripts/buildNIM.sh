#!/bin/bash

BANNER="NGINX Management Suite Docker image builder\n\n
This tool builds a Docker image to run NGINX Management Suite\n\n
=== Usage:\n\n
$0 [options]\n\n
=== Options:\n\n
-h\t\t\t- This help\n
-t [target image]\t- The Docker image name to be created\n
-s\t\t\t- Enable Second Sight (https://github.com/F5Networks/SecondSight/) - optional\n\n
Manual build:\n\n
-n [filename]\t\t- The NGINX Instance Manager .deb package filename\n
-a [filename]\t\t- The API Connectivity Manager .deb package filename - optional\n
-w [filename]\t\t- The Security Monitoring .deb package filename - optional\n\n
Automated build:\n\n
-i\t\t\t- Automated build - requires cert & key\n
-C [file.crt]\t\t- Certificate file to pull packages from the official NGINX repository\n
-K [file.key]\t\t- Key file to pull packages from the official NGINX repository\n
-A\t\t\t- Enable API Connectivity Manager\n
-W\t\t\t- Enable Security Monitoring\n\n
=== Examples:\n\n
Manual build:\n
\t$0 -n nim-files/nms-instance-manager_2.6.0-698150575~jammy_amd64.deb \\\\\n
\t\t-a nim-files/nms-api-connectivity-manager_1.2.0.668430332~jammy_amd64.deb \\\\\n
\t\t-w nim-files/nms-sm_1.0.0-697204659~jammy_amd64.deb \\\\\n
\t\t-t my.registry.tld/nginx-nms:2.6.0\n\n
Automated build:\n
\t$0 -i -C nginx-repo.crt -K nginx-repo.key\n
\t\t-A -W -t my.registry.tld/nginx-nms:2.6.0\n
"

# Defaults
COUNTER=false
ACM_IMAGE=nim-files/.placeholder

while getopts 'hn:a:w:t:siC:K:AW' OPTION
do
	case "$OPTION" in
		h)
			echo -e $BANNER
			exit
		;;
		n)
			DEBFILE=$OPTARG
		;;
		a)
			ACM_IMAGE=$OPTARG
		;;
		w)
			SM_IMAGE=$OPTARG
		;;
		t)
			IMGNAME=$OPTARG
		;;
		s)
			COUNTER=true
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
		A)
			ADD_ACM=true
		;;
		W)
			ADD_SM=true
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
        docker build --no-cache --build-arg NIM_DEBFILE=$DEBFILE --build-arg BUILD_WITH_SECONDSIGHT=$COUNTER \
                --build-arg ACM_IMAGE=$ACM_IMAGE --build-arg SM_IMAGE=$SM_IMAGE -t $IMGNAME .
else
	DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.automated --secret id=nginx-key,src=$NGINX_KEY --secret id=nginx-crt,src=$NGINX_CERT \
                --build-arg ADD_ACM=$ADD_ACM --build-arg ADD_SM=$ADD_SM --build-arg BUILD_WITH_SECONDSIGHT=$COUNTER \
                -t $IMGNAME .
fi

docker push $IMGNAME
