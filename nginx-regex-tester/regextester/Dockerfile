FROM nginx:latest

COPY start.sh /usr/local/sbin
RUN chmod +x /usr/local/sbin/start.sh

RUN apt-get update && apt-get install -y -q wget curl apt-transport-https lsb-release ca-certificates gnupg

RUN wget -q -O - https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg
RUN wget -q -O - https://unit.nginx.org/keys/nginx-keyring.gpg | gpg --dearmor > /usr/share/keyrings/nginx-keyring.gpg

RUN rm /etc/nginx/conf.d/*
COPY regextester.conf /etc/nginx/conf.d

RUN printf "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/debian/ `lsb_release -cs` unit" > /etc/apt/sources.list.d/unit.list
RUN printf "deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/debian/ `lsb_release -cs` unit" >> /etc/apt/sources.list.d/unit.list
RUN apt-get update && apt-get install -y unit php7.0 unit-php

COPY regextester.php /usr/share/nginx/html
COPY unitphp.config /srv

RUN ln -sf /dev/stderr /var/log/unit.log

EXPOSE 80 8000 9000 9080

CMD ["/usr/local/sbin/start.sh"]
