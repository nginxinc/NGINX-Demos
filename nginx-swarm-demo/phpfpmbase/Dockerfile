FROM dinkel/nginx-phpfpm

RUN apt-get update
RUN apt-get install -y -q wget curl
RUN apt-get install -y php5-curl

COPY nginx.conf /etc/nginx/
COPY default.conf /etc/nginx/conf.d/
COPY www.conf /etc/php5/fpm/pool.d/
