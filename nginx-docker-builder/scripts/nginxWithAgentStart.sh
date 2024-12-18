#!/bin/bash

NAMESPACE=nim-test

case $1 in
	'start')
		kubectl create namespace $NAMESPACE

		pushd manifests/
		kubectl apply -n $NAMESPACE -f .
		popd
	;;
	'stop')
		kubectl delete namespace $NAMESPACE
	;;
	*)
		echo "$0 [start|stop]"
		exit
	;;
esac
