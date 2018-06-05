#!/bin/sh

unitd --modules /usr/lib/unit/modules/ --log /var/log/unit.log

i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" localhost`
if [ "$i" != "200" ]; then
    echo "Unit failed to start"
    exit 1
fi

echo "Started Unit"

i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" -X PUT -d @/srv/app/app.config localhost`

if [ "$i" != "200" ]; then
    echo "Unit configuration failed"
    exit 1
fi

echo "Unit configured"

while [ "$i" = "200" ];
do
    sleep 30;
    i=`curl --unix-socket /run/control.unit.sock -s -o /dev/null -w "%{http_code}" localhost`
done

echo "The Unit start script has exited"

