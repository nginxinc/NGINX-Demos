#!/bin/bash

#####################################################################
# Copyright (C) 2015 Nginx, Inc.
#
# This script is intended for internal NGINX use and requires a
# Github account with access to the show-demos repository.
#
# It will extract the demo files from Github and create the needed
# Docker images.   
#
# This script does a fresh install and will not proceed if the
# demo directory $checkoutDir/$autoscaleDir already exists.
#
# $checkoutDir is prompted for, but the entered vaule is not validated.
#
# $autoscaleDir is the name of the directory on Dockerhub. Note that
# the entered vaule is not validated.
#
# Perquisites: ubuntu 14.04 (What this demo has been tested on)
#              docker 1.7+  (Lastest version will be installed if 
#                            not already installed)
#              git 1.9+     (Lastest version will be installed if
#                            not already installed)
#              siege 3.0.5+ (Lastest version will be installed if
#                            not already installed)
#              curl         (Lastest version will be installed if
#                            not already installed)
#####################################################################

checkoutDir=/srv/NGINX-Demos
autoscaleDir=autoscaling-demo
remoteHTTPS=https://github.com/nginxinc/NGINX-Demos.git

#####################################################################
# Function getCheckoutDir
#
# Prompt for the directory where the files will be extracted to.
#####################################################################
getCheckoutDir() {

    dirSet=false
    until $dirSet; do
        echo -en "\n\nWhere do you want to install the demo files? ($checkoutDir): "
        read -e newDir
        if [ "$newDir" ]; then
            checkoutDir=$newDir
            dirSet=true
        else
            dirSet=true
        fi
    done
    echo ""
    return 0
}

#####################################################################
# Function checksystem
#
# Check the system to make sure that the demo directory can be
# created and also to see if docker, git and curl are installed.
#####################################################################
checksystem() {

    if [ ! -f /etc/ssl/nginx/nginx-repo.crt ] || [ ! -f /etc/ssl/nginx/nginx-repo.key ]; then
        echo ">>> nginx-repo.crt and nginx-repo.key must be in /etc/ssl/nginx"
        return 1
    fi

    if [ -d $checkoutDir ] || [ -f $checkoutDir ]; then
        echo ">>> $checkoutDir already exists"
        return 1
    fi

    missing=false

    checkCurl=`which curl`
    if [ ! "$checkCurl" ]; then
        echo "    curl not installed"
        missing=true
    fi
    
    checkDocker=`which docker`
    if [ ! "$checkDocker" ]; then
        echo "    Docker not installed"
        missing=true
    fi

    checkGit=`which git`
    if [ ! "$checkGit" ]; then
        echo "    git not installed"
        missing=true
    fi

    checkSiege=`which siege`
    if [ ! "$checkSiege" ]; then
        echo "    siege not installed"
        missing=true
    fi

    if $missing; then
        echo -en "\nWould you like the missing software to be installed? (y/n): "
        while [ :: ]; do
            read -s -N 1 rc
            case "$rc" in
                y|Y)
                    break
                    ;;
                n|N)
                    echo
                    exit 1
                    ;;
                *)
                    echo "Please use 'y' or 'n'"
                    ;;
            esac
        done
        
        echo ""

        apt-get update

        if [ ! "$checkCurl" ]; then
            echo ">>> Install curl"
            apt-get install -y curl
        fi

        if [ ! "$checkDocker" ]; then
            echo ">>> Install docker"
            curl -sSL https://get.docker.com/ | sh
        fi

        if [ ! "$checkGit" ]; then
            echo ">>> Install git"
            apt-get install -y git
        fi

        if [ ! "$checkSiege" ]; then
            echo ">>> Install siege"
            apt-get install -y siege
        fi
        
    fi
}

#####################################################################
# Function gitcheckout
#
# Get all the demo files.  The user will be prompted twice to 
# login to Github.
#####################################################################
gitcheckout() {

    if [ -f $checkoutDir ]; then
        echo ">>> File $checkoutDir already exists.  Cannot create a directory $checkoutDir"
        exit 0
    fi
    if [ ! -d "$checkoutDir" ]; then
        mkdir $checkoutDir
    fi
    cd $checkoutDir
    git init
    if [ "$?" -gt 0 ]; then
        echo ">>> Error from git init"
        exit 0
    fi
    git remote add -f origin $remoteHTTPS && git fetch origin
    if [ "$?" -gt 0 ]; then
        echo ">>> Error from git remote and fetch"
        exit 0
    fi
    git config core.sparseCheckout true
    if [ "$?" -gt 0 ]; then
        echo ">>> Error from git config"
        exit 0
    fi
    echo "$autoscaleDir" > .git/info/sparse-checkout
    git checkout master
    if [ "$?" -gt 0 ]; then
        echo ">>> Error from git checkout"
        exit 0
    fi
    return 0
}

#####################################################################
## Main
#####################################################################
#####################################################################

echo ""
echo "This script will install the autoscaling demo."
echo ""
echo "The files nginx-repo.crt and nginx-repo.key must be in /etc/ssl/nginx."
echo ""
echo "You must have a Github account with access to the show-demos repository." 
echo "You will be prompted twice for your userid and password."  
echo ""
echo "The system will be checked to make sure that curl, docker, git and siege"
echo "are installed.  If any are not, you will prompted to install them."
echo ""
echo "The script will not proceed if the directoy $checkoutDir/$autoscaleDir"
echo "already exists."
echo ""

echo -n "Do you want to install the autoscale demo? (y/n): "

while [ :: ]; do
    read -s -N 1 rc
    case "$rc" in
        y|Y)
            break
            ;;
        n|N)
            echo
            exit 1
            ;;
        *)
            echo "Please use 'y' or 'n'"
            ;;
    esac
done

getCheckoutDir

if ! checksystem; then
    exit 1
fi

mkdir $checkoutDir

# Get the files from Github
echo -e "\n\nGet files from Github"
if ! gitcheckout; then
    echo ">>> There was an error getting the files from Github"
    exit 1
fi

echo ">>> Files retrieved from Github. Create Docker images"

# Copy crt and key
cp /etc/ssl/nginx/nginx-repo.crt $checkoutDir/$autoscaleDir/docker_base
cp /etc/ssl/nginx/nginx-repo.key $checkoutDir/$autoscaleDir/docker_base

echo ">>> Create NGINX Plus Docker image"
cd $checkoutDir/$autoscaleDir/docker_base
./createbaseimage.sh
if [ "$?" -gt 0 ]; then
    echo ">>> Error creating base NGINX Plus Docker image"
    exit 1
fi
cd $checkoutDir/$autoscaleDir/docker_lb
./createlbimage.sh
if [ "$?" -gt 0 ]; then
    echo ">>> Error creating load balancer NGINX Plus Docker image"
    exit 1
fi
cd $checkoutDir/$autoscaleDir/docker_ws
./createwsimage.sh
if [ "$?" -gt 0 ]; then
    echo ">>> Error creating web server NGINX Plus Docker image"
    exit 1
fi
  
# Pull the Elasticsearch image if it isn't already there
find=`docker images | grep -c elasticsearch`
if [ "$find" -eq 0 ]; then
    echo ">>> Get Elasticsearch image"
    docker pull elasticsearch
fi
if [ "$?" -gt 0 ]; then
    echo ">>> Error pulling Elasticsearch image"
    exit 1
fi

echo ">>> Demo setup complete"
