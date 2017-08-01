#!/bin/bash

sudo apt-get update && sudo apt-get -y upgrade
sudo wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
sudo apt-get install apt-transport-https lsb-release ca-certificates
sudo printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list
sudo wget -q -O /etc/apt/apt.conf.d/90nginx https://cs.nginx.com/static/files/90nginx
sudo apt-get update
sudo apt-get install -y nginx-plus
sudo service nginx start
