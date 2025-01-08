#!/bin/bash

# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/#docker_plus

BANNER="NGINX Docker Image builder\n\n
This tool builds a Docker image to run NGINX Plus/Open Source, NGINX App Protect WAF and NGINX Agent\n\n
=== Usage:\n\n
$0 [options]\n\n
=== Options:\n\n
-h\t\t\t- This help\n
-t [target image]\t- The Docker image to be created\n
-C [file.crt]\t\t- Certificate to pull packages from the official NGINX repository\n
-K [file.key]\t\t- Key to pull packages from the official NGINX repository\n
-w\t\t\t- Add NGINX App Protect WAF (requires NGINX Plus)\n
-O\t\t\t- Use NGINX Open Source instead of NGINX Plus\n
-u\t\t\t- Build unprivileged image (only for NGINX Plus)\n
-a\t\t\t- Add NGINX Agent\n\n
=== Examples:\n\n
NGINX Plus and NGINX Agent image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-docker:plus-agent-root -a\n\n

NGINX Plus, NGINX App Protect WAF and NGINX Agent image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-docker:plus-nap-agent-root -w -a\n\n

NGINX Plus, NGINX App Protect WAF and NGINX Agent unprivileged image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-docker:plus-nap-agent-nonroot -w -u -a\n\n

NGINX Opensource and NGINX Agent image:\n
  $0 -O -t registry.ff.lan:31005/nginx-docker:oss-root -a\n"

while getopts 'ht:C:K:awOu' OPTION
do
	case "$OPTION" in
		h)
			echo -e $BANNER
			exit
		;;
		t)
			IMAGENAME=$OPTARG
		;;
		C)
			NGINX_CERT=$OPTARG
		;;
		K)
			NGINX_KEY=$OPTARG
		;;
		a)
			NGINX_AGENT=true
		;;
		w)
			NAP_WAF=true
		;;
		O)
			NGINX_OSS=true
		;;
		u)
			UNPRIVILEGED=true
		;;
	esac
done

if [ -z "$1" ]
then
	echo -e $BANNER
	exit
fi

if [ -z "${IMAGENAME}" ]
then
        echo "Docker image name is required"
        exit
fi

if ([ -z "${NGINX_OSS}" ] && ([ -z "${NGINX_CERT}" ] || [ -z "${NGINX_KEY}" ]) )
then
        echo "NGINX certificate and key are required for automated installation"
        exit
fi

echo "=> Target docker image is $IMAGENAME"

if [ "${NGINX_AGENT}" ]
then
	echo "=> Building with NGINX Agent"
fi

if ([ ! -z "${NAP_WAF}" ] && [ -z "${NGINX_OSS}" ])
then
	echo "=> Building with NGINX App Protect WAF"
fi

if [ -z "${NGINX_OSS}" ]
then
	if [ -z "${UNPRIVILEGED}" ]
	then
		DOCKERFILE_NAME=Dockerfile.plus
		echo "=> Building with NGINX Plus"
	else
		DOCKERFILE_NAME=Dockerfile.plus.unprivileged
		echo "=> Building with NGINX Plus unprivileged"
	fi

	DOCKER_BUILDKIT=1 docker build --no-cache -f $DOCKERFILE_NAME \
		--secret id=nginx-key,src=$NGINX_KEY --secret id=nginx-crt,src=$NGINX_CERT \
		--build-arg NAP_WAF=$NAP_WAF --build-arg NGINX_AGENT=$NGINX_AGENT \
		-t $IMAGENAME .
else
	echo "=> Building with NGINX Open Source"
	DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.oss \
		--build-arg NGINX_AGENT=$NGINX_AGENT \
		-t $IMAGENAME .
fi

echo "=> Build complete for $IMAGENAME"
