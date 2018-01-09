#!/bin/bash
# Copyright (C) 2017 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Checks that the environment is ready to build the NGINX Plus
# image and run the demo.

warnCount=0
errCount=0

echo

# Check that the cert and key exist
fileName="nginxplus/nginx-repo.crt"
if [ -f $fileName ]; then
    echo -e "$fileName found [\e[32mOK\e[39m]"
else
    echo -e "$fileName not found [\e[31mError\e[39m]"
    let errCount++
fi

fileName="nginxplus/nginx-repo.key"
if [ -f $fileName ]; then
    echo -e "$fileName found [\e[32mOK\e[39m]"
else
    echo -e "$fileName not found [\e[31mError\e[39m]"
    let errCount++
fi

echo

# Check for demo-magic.sh
fileName="demo-magic.sh"
if [ -f $fileName ]; then
    echo -e "$fileName found [\e[32mOK\e[39m]"
else
    echo -e "$fileName not found [\e[33mWarning\e[39m]"
    let warnCount++
fi

echo

# Check for a dockerhost entry in /etc/hosts
found=`grep -cw dockerhost /etc/hosts`
if [ $found = 1 ]; then
    echo -e "/etc/hosts entry for dockerhost found [\e[32mOK\e[39m]"
else
    echo -e "/etc/hosts entry for dockerhost not found [\e[31mError\e[39m]"
    let errCount++
fi

echo

# Check the HOST_IP environment variable
docker0=`ip addr | grep docker0 | grep inet | awk -F '[ /]+' '{print $3}'`
if [ "$docker0" ]; then
    if [ $HOST_IP ]; then
        if [ "$HOST_IP" = "$docker0" ]; then
            echo -e "HOST_IP environment set to docker0 IP address [\e[32mOK\e[39m]"
        else
            echo -e "HOST_IP environment not set to docker0 IP address ($docker0) [\e[33mWarning\e[39m]"
            let warnCount++
        fi
    else
        echo -e "HOST_IP environment not set to docker0 IP address ($docker0) [\e[33mWarning\e[39m]"
        let warnCount++
    fi
else
    echo -e "docker0 IP address not found [\e[31mError\e[39m]"
    let errCount++
fi

echo

# Check that the Docker API is working
response=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:2375/version)
if [ $response = 200 ]; then
    echo -e "The Docker API is working [\e[32mOK\e[39m]"
else
    echo -e "The Docker API is not working [\e[31mError\e[39m]"
    echo -e "    Make sure the required edits are made to /lib/systemd/system/docker.service"
    let errCount++
fi

echo

# Check for the images
image=bhc-nginxplus
found=`docker images $image | grep -cw $image`
if [ $found = 1 ]; then
    echo -e "docker image $image found [\e[32mOK\e[39m]"
else
    echo -e "docker image $image not found [\e[33mWarning\e[39m]"
    echo -e "    Run setup_images.sh to build the image"
    let warnCount++
fi

image=bhc-unit
found=`docker images $image | grep -cw $image`
if [ $found = 1 ]; then
    echo -e "docker image $image found [\e[32mOK\e[39m]"
else
    echo -e "docker image $image not found [\e[33mWarning\e[39m]"
    echo -e "    Run setup_images.sh to build the image"
    let warnCount++
fi

echo

if [ $warnCount -eq 1 ]; then
    echo "There was 1 warning"
else
    if [ $warnCount -gt 1 ]; then
        echo "There were $warnCount warnings"
    fi
fi

if [ $errCount -eq 1 ]; then
    echo "There was 1 error"
else
    if [ $errCount -gt 1 ]; then
        echo "There were $errCount errors"
    fi
fi

if [ $warnCount -eq 0 ] && [ $errCount -eq 0 ]; then
    echo "There where no warnings or errors"
fi
