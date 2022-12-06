#!/bin/bash

case $1 in
	'clean')
		kubectl delete secret nim2.f5.ff.lan -n nginx-nim2
		rm nim2.f5.ff.lankey nim2.f5.ff.lan.crt
	;;
	'install')
		openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout nim2.f5.ff.lan.key -out nim2.f5.ff.lan.crt -config nim2.f5.ff.lan.cnf
		kubectl create secret tls nim2.f5.ff.lan --key nim2.f5.ff.lan.key --cert nim2.f5.ff.lan.crt -n nginx-nim2
	;;
	*)
		echo "$0 [clean|install]"
		exit
	;;
esac
