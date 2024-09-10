FROM ubuntu:24.04

MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

# Set the debconf front end to Noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get install -y -q wget apt-transport-https

# Download certificate and key from the customer portal (https://cs.nginx.com)
# and copy to the build context
ADD nginx-repo.crt /etc/ssl/nginx/
ADD nginx-repo.key /etc/ssl/nginx/

# Get other files required for installation
RUN wget -q -O /etc/ssl/nginx/CA.crt https://cs.nginx.com/static/files/CA.crt
RUN wget -q -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN wget -q -O /etc/apt/apt.conf.d/90nginx https://cs.nginx.com/static/files/90nginx

RUN printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" >/etc/apt/sources.list.d/nginx-plus.list

# Install NGINX Plus 
RUN apt-get update && apt-get install -y nginx-plus nginx-plus-module-njs

# forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 6379 8080

ADD nginx.conf /etc/nginx/nginx.conf
RUN rm -v /etc/nginx/conf.d/*
ADD status.conf /etc/nginx/conf.d/status.conf
ADD redis_command.js /etc/nginx/redis_command.js
ADD logo.png /usr/share/nginx/html/logo.png

CMD ["nginx", "-g", "daemon off;"]
