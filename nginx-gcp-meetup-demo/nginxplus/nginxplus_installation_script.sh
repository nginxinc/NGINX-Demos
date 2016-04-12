#!/bin/sh

sudo mkdir -p /etc/ssl/nginx
sudo mv nginx-repo.crt nginx-repo.key /etc/ssl/nginx
sudo wget -P /etc/ssl/nginx https://cs.nginx.com/static/files/CA.crt
sudo wget http://nginx.org/keys/nginx_signing.key && sudo apt-key add nginx_signing.key
sudo apt-get install apt-transport-https libgnutls26 libcurl3-gnutls
printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list
sudo wget -P /etc/apt/apt.conf.d http://cs.nginx.com/static/files/90nginx
sudo apt-get update
sudo apt-get install nginx-plus

sudo rm /etc/nginx/conf.d/*
sudo mv meetup.conf /etc/nginx/conf.d/
sudo mkdir /etc/nginx/my.conf.d/
sudo mv udp.conf /etc/nginx/my.conf.d/
printf "include /etc/nginx/my.conf.d/*.conf;\n" | sudo tee -a /etc/nginx/nginx.conf

wget https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash ./install-logging-agent.sh

curl -O https://repo.stackdriver.com/stack-install.sh
sudo bash stack-install.sh --write-gcm
sudo mv nginx-stackdriver.conf /etc/nginx/conf.d/
sudo mv stackdriver-plugin.conf /opt/stackdriver/collectd/etc/collectd.d/

sudo service nginx restart
sudo service stackdriver-agent restart

sudo apt-get install jq git zip -y
echo 'filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab' > .vimrc
git clone -v https://github.com/evanmiller/nginx-vim-syntax
rm nginx-vim-syntax/README.md
mkdir -v .vim
cp -rv nginx-vim-syntax/* .vim/
rm -rf nginx-vim-syntax/
