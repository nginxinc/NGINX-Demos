FROM ubuntu:16.04

# Download certificate and key from the customer portal (https://cs.nginx.com)
# and copy to the build context
ADD nginx-repo.crt /etc/ssl/nginx/
ADD nginx-repo.key /etc/ssl/nginx/

# For debugging curl and/or dnsutils can be useful, but installing them will increase the size of the image.
# To install them add the line: apt-get install -y -q curl dnsutils && \
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && apt-get install -y -q wget apt-transport-https lsb-release ca-certificates && \
    wget -q -O - http://nginx.org/keys/nginx_signing.key | apt-key add - && \
    wget -q -O /etc/apt/apt.conf.d/90nginx https://cs.nginx.com/static/files/90nginx && \
    printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" >/etc/apt/sources.list.d/nginx-plus.list && \
    apt-get update && apt-get install -y nginx-plus &&\
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    apt-get remove --purge --auto-remove -y gnupg1 && \
    rm -rf /var/lib/apt/lists/*

# copy the config files
COPY config/nginx.conf /etc/nginx/
COPY content/* /usr/share/nginx/html/

EXPOSE 80 8001 8002 8003 8082

CMD ["nginx", "-g", "daemon off;"]
