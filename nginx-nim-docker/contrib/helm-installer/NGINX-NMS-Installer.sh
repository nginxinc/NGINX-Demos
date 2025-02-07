#!/bin/bash

HEADER="NGINX Management Suite Helm Chart installation script"
BANNER="$HEADER\n\n
Usage:\n\n
$0 [options]\n\n
Options:\n\n
-h\t\t\t- This help\n\n
-i [filename]\t\t- NGINX Management Suite Helm installation file (mandatory)\n
-r [registry FQDN]\t- Private registry FQDN (mandatory)\n\n
-s [pull secret]\t- Private registry pull secret (optional)\n
-p [admin password]\t- NGINX Management Suite admin password (optional, default is 'admin')\n
-n [namespace]\t\t- Destination namespace to install to (optional, default is the current namespace)\n
-P [true|false]\t- Set persistent volumes usage (optional, default is 'true')\n\n
Example:\n\n
$0 -i nms-helm-2.5.1.tar.gz -r myregistry.k8s.local:31005 -s MyPullSecret -p adminP4ssw0rd -n nms-namespace\n
"

while getopts 'hi:r:s:p:n:P:' OPTION
do
	case "$OPTION" in
		h)
			echo -e $BANNER
			exit
		;;
		i)
			HELMFILE=$OPTARG
		;;
		r)
			REGISTRY=$OPTARG
		;;
		s)
			PULLSECRET=$OPTARG
		;;
		p)
			ADMINPASS=$OPTARG
		;;
		n)
			NAMESPACE=$OPTARG
		;;
		P)
			PERSISTENTVOLUMES=$OPTARG
		;;
		*)
			exit
		;;
	esac
done

if [ $# == 0 ] || [ "$HELMFILE" = "" ] || [ "$REGISTRY" = "" ]
then
	echo -e $BANNER
	exit
fi

echo -e "$HEADER\n\n-- Running preflight checks"
REQUIRED_COMMANDS="tar helm openssl"

for RC in $REQUIRED_COMMANDS
do
	echo -n "$RC... "
	type $RC >/dev/null 2>&1
	if [ ! $? = 0 ]
	then
		echo -e "Not found, aborting"
		exit
	else
		echo -e "OK"
	fi
done

RECAP="
Release file:\t\t\t$HELMFILE\n
Private registry:\t\t$REGISTRY\n
Private registry pull secret:\t$PULLSECRET\n
Destination namespace:\t\t${NAMESPACE:=nms}\n
Persistent volumes:\t\t${PERSISTENTVOLUMES:=true}\n
Admin password:\t\t${ADMINPASS:=admin}\n"

DRYRUN="\n-- Installing using:\n\n$RECAP"

echo -e $DRYRUN

read -p "Do you want to proceed (YES/no)? " PROCEED

if [ ! "$PROCEED" = "YES" ]
then
	echo "Aborting installation"
	exit
fi

echo

if [ ! -f $HELMFILE ]
then
	echo "$HELMFILE not found, aborting"
	exit
fi

NMSRELEASE=`basename $HELMFILE | sed "s/nms-helm-//g"|sed "s/.tar.gz//g"`
echo "-- Processing NMS Helm Chart for release $NMSRELEASE"

DSTDIR=`mktemp -d`

echo "-- Decompressing $HELMFILE"
tar -xf $HELMFILE -C $DSTDIR
pushd $DSTDIR > /dev/null

IMAGES=`ls *.tar.gz`

for I in $IMAGES
do
	IMGNAME=`echo $I:$NMSRELEASE | sed "s/-$NMSRELEASE.tar.gz//g"`

	echo ".. Importing docker image for $I"
	PUSHEDIMG=`docker load -i $I | tail -n1 | awk '{print $3}'`

	#echo ".. Tagging $PUSHEDIMG as $REGISTRY/$IMGNAME"
	#docker tag $PUSHEDIMG $REGISTRY/$IMGNAME

	echo ".. Pushing $REGISTRY/$IMGNAME to private registry"
	docker push $REGISTRY/$IMGNAME > /dev/null
done

echo "-- Decompressing helm chart"
tar zxmf nms-hybrid-$NMSRELEASE.tgz

echo "-- Running helm install"
helm install \
--set core.persistence.enable=${PERSISTENTVOLUMES:true} \
--set dpm.persistence.enable=${PERSISTENTVOLUMES:true} \
--set integrations.persistence.enable=${PERSISTENTVOLUMES:true} \
--set imagePullSecrets[0].name=${PULLSECRET:-""} \
--set adminPasswordHash=`openssl passwd -1 ${ADMINPASS:=admin}` \
--set namespace=$NAMESPACE \
--set apigw.image.repository=$REGISTRY/nms-apigw \
--set apigw.image.tag=$NMSRELEASE \
--set core.image.repository=$REGISTRY/nms-core \
--set core.image.tag=$NMSRELEASE \
--set dpm.image.repository=$REGISTRY/nms-dpm \
--set dpm.image.tag=$NMSRELEASE \
--set ingestion.image.repository=$REGISTRY/nms-ingestion \
--set ingestion.image.tag=$NMSRELEASE \
--set integrations.image.repository=$REGISTRY/nms-integrations \
--set integrations.image.tag=$NMSRELEASE \
nim ./nms-hybrid
popd > /dev/null

rm -r $DSTDIR

echo -e "\n-- Installation complete\n"
echo -e $RECAP
