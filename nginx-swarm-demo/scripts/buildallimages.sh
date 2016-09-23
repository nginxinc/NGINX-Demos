#!/bin/bash
# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Builds all the Docker images.  Each build script uses the variable
# dockerPrefix, specified in the constants.inc file, to prefix the
# image  name with.  If blank, images will only be available in the
# local repo.  If a DockerHub repo is going to be used to store the
# images, then the user must be logged into the corresponding DockerHub
# account, using the "docker login" command. 

cd "${BASH_SOURCE%/*}"

cd ../hello
./createhelloimage.sh
cd ../nginxbasic
./createnginxbasicimage.sh
cd ../phpfpmbase
./createphpfpmbaseimage.sh
cd ../service1
./createservice1image.sh
cd ../service2
./createservice2image.sh
cd ../nginxplus
./createnginxplusimage.sh
cd ../etcd
./createetcdimage.sh
