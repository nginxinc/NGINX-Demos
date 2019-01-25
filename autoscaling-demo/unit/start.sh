#!/bin/sh

unitd --modules /usr/lib/unit/modules/ --log /var/log/unit.log

i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" localhost/config`
if [ "$i" != "200" ]; then
    echo "Unit failed to start: Status $1"
    exit 1
fi

echo "Started Unit"

i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" -X PUT -d @/srv/app/app.config localhost/config`

if [ "$i" != "200" ]; then
    echo "Unit configuration failed: Status $i"
    exit 1
fi

echo "Unit configured"

while [ "$i" = "200" ];
do
    sleep 30;
    i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" localhost/config`
    if [ "$i" != "200" ]; then
        echo "Error from Unit API: Status $i"
    fi
done

echo "The Unit start script has exited"
