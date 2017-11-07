FROM ubuntu:16.04
MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

# Set the debconf frontend to Noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && apt-get install -y -q wget apt-transport-https lsb-release ca-certificates

# Download certificate and key from the customer portal https://cs.nginx.com
# and copy to the build context
ADD nginx-repo.crt /etc/ssl/nginx/
ADD nginx-repo.key /etc/ssl/nginx/

# Get other files required for installation
RUN wget -q -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN wget -q -O /etc/apt/apt.conf.d/90nginx https://cs.nginx.com/static/files/90nginx
RUN printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" >/etc/apt/sources.list.d/nginx-plus.list

# A hotfix if you have nginx user in your system already.
# Otherwise you will see error adduser: `/usr/bin/chfn -f nginx user nginx' returned error code 1. Exiting.
# RUN ln -s -f /bin/true /usr/bin/chfn

# Install NGINX Plus
RUN apt-get update && apt-get install -y nginx-plus

# forward request logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
