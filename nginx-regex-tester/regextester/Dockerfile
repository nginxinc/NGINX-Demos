FROM nginx/unit:1.24.0-php8.0

COPY regextester.php /usr/share/nginx/html
COPY unitphp.config /srv

RUN ln -sf /dev/stderr /var/log/unit.log

EXPOSE 80 8000 9000 9080
