#!/bin/bash

BANNER="NGINX Management Suite Docker image builder\n\n
This tool builds a Docker image to run NGINX Management Suite\n\n
=== Usage:\n\n
$0 [options]\n\n
=== Options:\n\n
-h\t\t\t- This help\n
-n [filename]\t\t- The NGINX Instance Manager .deb package filename\n
-a [filename]\t\t- The API Connectivity Manager .deb package filename - optional\n
-w [filename]\t\t- The Security Monitoring .deb package filename - optional\n
-t [target image]\t- The Docker image name to be created\n
-s\t\t\t- Enable Second Sight (https://github.com/F5Networks/SecondSight/) - optional\n\n
=== Examples:\n\n
$0 -n nim-files/nms-instance-manager_2.6.0-698150575~jammy_amd64.deb \\\\\n
\t-a nim-files/nms-api-connectivity-manager_1.2.0.668430332~jammy_amd64.deb \\\\\n
\t-w nim-files/nms-sm_1.0.0-697204659~jammy_amd64.deb \\\\\n
\t-t my.registry.tld/nginx-nms:2.6.0\n
"

# Defaults
COUNTER=false
ACM_IMAGE=nim-files/.placeholder

while getopts 'hn:a:w:t:s' OPTION
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
	esac
done

if [ "$1" = "" ] || [ "$DEBFILE" = "" ] || [ "$IMGNAME" = "" ]
then
        echo -e $BANNER
        exit
fi

echo "==> Building NGINX Management Suite docker image"

docker build --no-cache --build-arg NIM_DEBFILE=$DEBFILE --build-arg BUILD_WITH_SECONDSIGHT=$COUNTER --build-arg ACM_IMAGE=$ACM_IMAGE --build-arg SM_IMAGE=$SM_IMAGE -t $IMGNAME .
docker push $IMGNAME
