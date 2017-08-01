#!/bin/bash

sudo apt-get update && sudo apt-get -y upgrade
sudo wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
sudo sed -i "$ a\deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx\ndeb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" /etc/apt/sources.list
sudo apt-get remove -y nginx-common
sudo apt-get update
sudo apt-get install -y nginx
sudo service nginx start
