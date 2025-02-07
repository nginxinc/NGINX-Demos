#!/bin/bash

# Makes sure that Clickhouse is up and running - dedicated pod

RETCODE=-1
while [ ! $RETCODE = 0 ]
do
        nc -z $NIM_CLICKHOUSE_ADDRESS $NIM_CLICKHOUSE_PORT
        RETCODE=$?
	echo "Waiting for ClickHouse..."
        sleep 3
done

if [ -f "/deployment/counter.enabled" ]
then
	export DATAPLANE_TYPE=NGINX_MANAGEMENT_SYSTEM
	export DATAPLANE_FQDN="https://127.0.0.1:443"
	export DATAPLANE_USERNAME=$NIM_USERNAME
	export DATAPLANE_PASSWORD=$NIM_PASSWORD
	export NMS_CH_HOST=$NIM_CLICKHOUSE_ADDRESS
	export NMS_CH_PORT=$NIM_CLICKHOUSE_PORT
	export NMS_CH_USER=$NIM_CLICKHOUSE_USERNAME
	export NMS_CH_PASS=$NIM_CLICKHOUSE_PASSWORD

	python3 /deployment/app.py &
fi

mkdir /nonexistent

/etc/nms/scripts/basic_passwords.sh $NIM_USERNAME $NIM_PASSWORD

# NGINX Management Suite version detection
# NMS >= 2.7.0 configuration is yaml
VERSION=`nms-core -v`
A=${VERSION%\/*}
B=${A##*\ }
RELEASE=`echo $B | awk -F- '{print $2"."$3"."$4}'`

echo -n "Detected NMS $RELEASE... "

case $RELEASE in
	2.4.0|2.5.0|2.5.1|2.6.0)
		echo "legacy nms.conf"
# Clickhouse configuration - dedicated pod
echo -e "

# Clickhouse config
clickhouse_address = $NIM_CLICKHOUSE_ADDRESS:$NIM_CLICKHOUSE_PORT
clickhouse_username = '$NIM_CLICKHOUSE_USERNAME'
clickhouse_password = '$NIM_CLICKHOUSE_PASSWORD'
" >> /etc/nms/nms.conf
	;;
	2.7.0|2.8.0|2.9.0|2.9.1|2.10.0|2.10.1|2.11.0|2.12.0)
		echo "YAML nms.conf <= 2.12"
# Clickhouse configuration - dedicated pod
echo -e "

# Clickhouse config
clickhouse:
  address: $NIM_CLICKHOUSE_ADDRESS:$NIM_CLICKHOUSE_PORT
  username: '$NIM_CLICKHOUSE_USERNAME'
  password: '$NIM_CLICKHOUSE_PASSWORD'
" >> /etc/nms/nms.conf
	;;
	*)
		echo "YAML nms.conf >= 2.13"
# Clickhouse configuration - dedicated pod
export NIM_CLICKHOUSE_ADDRESSPORT=$NIM_CLICKHOUSE_ADDRESS:$NIM_CLICKHOUSE_PORT
yq '.clickhouse.address=strenv(NIM_CLICKHOUSE_ADDRESSPORT)|.clickhouse.username=strenv(NIM_CLICKHOUSE_USERNAME)|.clickhouse.password=strenv(NIM_CLICKHOUSE_PASSWORD)' /etc/nms/nms.conf > /etc/nms/nms.conf-updated
mv /etc/nms/nms.conf-updated /etc/nms/nms.conf
chown nms:nms /etc/nms/nms.conf
chmod 644 /etc/nms/nms.conf

yq '.clickhouse.address="tcp://"+strenv(NIM_CLICKHOUSE_ADDRESSPORT)|.clickhouse.username=strenv(NIM_CLICKHOUSE_USERNAME)|.clickhouse.password=strenv(NIM_CLICKHOUSE_PASSWORD)' /etc/nms/nms-sm-conf.yaml > /etc/nms/nms-sm-conf.yaml-updated
mv /etc/nms/nms-sm-conf.yaml-updated /etc/nms/nms-sm-conf.yaml
chown nms:nms /etc/nms/nms-sm-conf.yaml
chmod 644 /etc/nms/nms-sm-conf.yaml
	;;
esac

# Start nms core - from /lib/systemd/system/nms-core.service
/bin/bash -c '`which mkdir` -p /var/lib/nms/dqlite/'
/bin/bash -c '`which mkdir` -p /var/lib/nms/secrets/'
/bin/bash -c '`which mkdir` -p /var/run/nms/'
/bin/bash -c '`which mkdir` -p /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/run/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/lib/nms/'
/bin/bash -c '`which chmod` 0775 /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /etc/nms/certs/services/core'
/bin/bash -c '`which chown` nms:nms /etc/nms/certs/services/ca.crt'
/bin/bash -c '`which chmod` 0700 /etc/nms/certs/services/core'
/bin/bash -c '`which chmod` 0600 /etc/nms/certs/services/core/*'
su - nms -c 'function repeat { while [ 1 ] ; do "$@" ; sleep 1 ; done; };repeat /usr/bin/nms-core &' -s /bin/bash

# Start nms dpm - from /lib/systemd/system/nms-dpm.service
/bin/bash -c '`which mkdir` -p /var/lib/nms/streaming/'
/bin/bash -c '`which mkdir` -p /var/lib/nms/dqlite/'
/bin/bash -c '`which mkdir` -p /var/run/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/lib/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/run/nms/'
/bin/bash -c '`which chown` -R nms:nms /etc/nms/certs/services/dataplane-manager'
/bin/bash -c '`which chown` nms:nms /etc/nms/certs/services/ca.crt'
/bin/bash -c '`which chmod` 0700 /etc/nms/certs/services/dataplane-manager'
/bin/bash -c '`which chmod` 0600 /etc/nms/certs/services/dataplane-manager/*'
su - nms -c 'function repeat { while [ 1 ] ; do "$@" ; sleep 1 ; done; };repeat /usr/bin/nms-dpm &' -s /bin/bash

# Start nms ingestion - from /lib/systemd/system/nms-ingestion.service
/bin/bash -c '`which mkdir` -p /var/run/nms/'
/bin/bash -c '`which mkdir` -p /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/log/nms/'
/bin/bash -c '`which chmod` 0775 /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/run/nms/'
su - nms -c 'function repeat { while [ 1 ] ; do "$@" ; sleep 1 ; done; };repeat /usr/bin/nms-ingestion &' -s /bin/bash

# Start nms integrations - from /lib/systemd/system/nms-integrations.service
/bin/bash -c '`which mkdir` -p /var/lib/nms/dqlite/'
/bin/bash -c '`which mkdir` -p /var/run/nms/'
/bin/bash -c '`which mkdir` -p /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/lib/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/run/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/log/nms/'
/bin/bash -c '`which chmod` 0775 /var/log/nms/'
/bin/bash -c '`which chown` nms:nms /etc/nms/certs/services/ca.crt'
su - nms -c 'function repeat { while [ 1 ] ; do "$@" ; sleep 1 ; done; };repeat /usr/bin/nms-integrations &' -s /bin/bash

sleep 5

# Start Security Monitoring
if [ -f /usr/bin/nms-sm ]
then
	su - nms -c 'function repeat { while [ 1 ] ; do "$@" ; sleep 1 ; done; };repeat /usr/bin/nms-sm start &' -s /bin/bash
fi

chmod 666 /var/run/nms/*.sock

/etc/init.d/nginx start

# License activation
if ((${#NIM_LICENSE[@]}))
then
	curl -s -X PUT -k https://127.0.0.1/api/platform/v1/license -u "$NIM_USERNAME:$NIM_PASSWORD" -d '{ "desiredState": { "content": "'$NIM_LICENSE'" }, "metadata": { "name": "license" } }' -H "Content-Type: application/json"
fi

while [ 1 ]
do
	sleep 60
done
