#!/bin/bash

# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/#docker_plus

BANNER="NGINX Plus & NGINX Instance Manager agent Docker image builder\n\n
This tool builds a Docker image to run NGINX Plus and NGINX Instance Manager agent\n\n
=== Usage:\n\n
$0 [options]\n\n
=== Options:\n\n
-h\t\t\t- This help\n
-t [target image]\t- The Docker image to be created\n
-C [file.crt]\t\t- Certificate to pull packages from the official NGINX repository\n
-K [file.key]\t\t- Key to pull packages from the official NGINX repository\n
-n [URL]\t\t- NGINX Instance Manager URL to fetch the agent\n
-d\t\t\t- Build support for NGINX API Gateway Developer Portal\n
-w\t\t\t- Add NGINX App Protect WAF\n\n
=== Examples:\n\n
NGINX Plus and NGINX Agent image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:2.7.0 -n https://nim.f5.ff.lan\n\n
NGINX Plus, NGINX App Protect WAF and NGINX Agent image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:2.7.0 -w -n https://nim.f5.ff.lan\n\n
NGINX Plus, Developer Portal support and NGINX Agent image:\n
  $0 -C nginx-repo.crt -K nginx-repo.key -t registry.ff.lan:31005/nginx-with-agent:2.7.0-devportal -d -n https://nim.f5.ff.lan
\n"

while getopts 'ht:C:K:a:n:dw' OPTION
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
		n)
			NMSURL=$OPTARG
		;;
		d)
			DEVPORTAL=true
		;;
		w)
			NAP_WAF=true
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

if [ -z "${NMSURL}" ]
then
        echo "NGINX Instance Manager URL is required"
        exit
fi

if ([ -z "${NGINX_CERT}" ] || [ -z "${NGINX_KEY}" ])
then
        echo "NGINX certificate and key are required for automated installation"
        exit
fi

echo "=> Target docker image is $IMAGENAME"

if [ ! -z "${DEVPORTAL}" ]
then
echo "=> Building with Developer Portal support"
fi

if [ ! -z "${NAP_WAF}" ]
then
echo "=> Building with NGINX App Protect WAF support"
fi

DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile \
	--secret id=nginx-key,src=$NGINX_KEY --secret id=nginx-crt,src=$NGINX_CERT \
	--build-arg NMS_URL=$NMSURL --build-arg DEVPORTAL=$DEVPORTAL --build-arg NAP_WAF=$NAP_WAF -t $IMAGENAME .

echo "=> Build complete for $IMAGENAME"
docker push $IMAGENAME
