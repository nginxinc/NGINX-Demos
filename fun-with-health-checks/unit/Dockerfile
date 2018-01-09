FROM ubuntu:xenial

COPY start.sh /usr/local/sbin
RUN chmod +x /usr/local/sbin/start.sh

RUN apt-get update 

# For testing purposes - can be removed if desired
RUN apt-get install -y procps net-tools

RUN apt-get install -y apt-transport-https curl wget

RUN apt-get install -y php7.0
RUN apt-get install -y php7.0-curl
RUN apt-get install -y python2.7
RUN apt-get install -y python-dev
RUN apt-get install -y stress

RUN wget http://nginx.org/keys/nginx_signing.key
RUN apt-key add nginx_signing.key
RUN echo "deb http://packages.nginx.org/unit/ubuntu/ xenial unit" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.nginx.org/unit/ubuntu/ xenial unit" >> /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y unit
RUN apt-get install -y unit-php unit-python2.7

EXPOSE 8443 9080

STOPSIGNAL SIGTERM

CMD ["/usr/local/sbin/start.sh"]
