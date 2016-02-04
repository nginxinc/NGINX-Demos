#!/bin/bash

# Set bash to exit after SIGINT, otherwise ctrl-c won't stop the script
trap "exit" INT

# Check if env var HOST_IP is set, set it if its not
if [[ -z "$HOST_IP" ]]; then
    echo "HOST_IP not set. Please set it & re-execute this script"
    exit
fi

while [ true ]; do
	for i in `seq 1 2`; do 
		docker exec -ti mysqld$i mysqladmin flush-hosts
	done 
	mysql -h $HOST_IP -u root -P 3306 --protocol=tcp -e "SHOW VARIABLES WHERE Variable_name = 'hostname';DO SLEEP(2);\q"
done
