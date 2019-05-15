#!/bin/sh

nginx

i=`curl -s -o /dev/null -w "%{http_code}" 0.0.0.0`
if [ "$i" != "200" ]; then
    echo "NGINX failed to start: Status $1"
    exit 1
fi

echo "NGINX started"

unitd --modules /usr/lib/unit/modules/ --log /var/log/unit.log

i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" localhost/config`
if [ "$i" != "200" ]; then
    echo "Unit failed to start: Status $1"
    exit 1
fi

echo "Unit started"

i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" -X PUT -d @/srv/unitphp.config http://localhost/config/`

if [ "$i" != "200" ]; then
    echo "Unit configuration failed: Status $1"
    exit 1
fi

echo "Unit configured"

while [ "$i" = "200" ];
do
    sleep 30;
    i=`curl -s -o /dev/null -w "%{http_code}" 0.0.0.0`
    if [ "$i" != "200" ]; then
        echo "NGINX is not running: Status $1"
    else
        i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" localhost`
        if [ "$i" != "200" ]; then
            echo "Unit is not running: Status $1"
        fi
    fi
done

echo "The NGINX and Unit start script has exited"
