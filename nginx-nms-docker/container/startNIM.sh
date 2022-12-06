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

/etc/nms/scripts/basic_passwords.sh $NIM_USERNAME $NIM_PASSWORD

# Clickhouse configuration - dedicated pod
echo -e "

# Clickhouse config
clickhouse_address = $NIM_CLICKHOUSE_ADDRESS:$NIM_CLICKHOUSE_PORT
clickhouse_username = '$NIM_CLICKHOUSE_USERNAME'
clickhouse_password = '$NIM_CLICKHOUSE_PASSWORD'
" >> /etc/nms/nms.conf

/etc/init.d/nginx start

# Start nms core - from /lib/systemd/system/nms-core.service
/bin/bash -c '`which mkdir` -p /var/lib/nms/dqlite/'
/bin/bash -c '`which mkdir` -p /var/lib/nms/secrets/'
/bin/bash -c '`which mkdir` -p /var/run/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/lib/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/run/nms/'
/bin/bash -c '`which chown` -R nms:nms /etc/nms/certs/services/core'
/bin/bash -c '`which chown` nms:nms /etc/nms/certs/services/ca.crt'
/bin/bash -c '`which chmod` 0700 /etc/nms/certs/services/core'
/bin/bash -c '`which chmod` 0600 /etc/nms/certs/services/core/*'
/usr/bin/nms-core &

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
/usr/bin/nms-dpm &

# Start nms ingestion - from /lib/systemd/system/nms-ingestion.service
/bin/bash -c '`which mkdir` -p /var/run/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/log/nms/'
/bin/bash -c '`which chown` -R nms:nms /var/run/nms/'
/usr/bin/nms-ingestion &

# Start API Connectivity Manager
sleep 5
/usr/bin/nms-acm server &

sleep 5

chmod 666 /var/run/nms/*.sock

# License activation
if ((${#NIM_LICENSE[@]}))
then
	curl -s -X PUT -k https://127.0.0.1/api/platform/v1/license -u "$NIM_USERNAME:$NIM_PASSWORD" -d '{ "desiredState": { "content": "'$NIM_LICENSE'" }, "metadata": { "name": "license" } }' -H "Content-Type: application/json"
fi

while [ 1 ]
do
	sleep 60
done
