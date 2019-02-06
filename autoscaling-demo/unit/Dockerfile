FROM nginx/unit:latest

COPY start.sh /usr/local/sbin
RUN mkdir -p /srv/app/content
COPY app.config /srv/app
COPY content /srv/app/content
RUN chmod +x /usr/local/sbin/start.sh

RUN apt-get update

# For testing purposes - can be removed if desired
RUN apt-get install -y procps net-tools

RUN apt-get install -y apt-transport-https curl wget
RUN apt-get install -y php7.0-curl
RUN apt-get install -y stress

RUN ln -sf /dev/stdout /var/log/unit.log

# Configure the app
COPY content/* /srv/app/content/
COPY app.config /var/lib/unit/conf.json

EXPOSE 8443 9080

STOPSIGNAL SIGTERM

CMD ["unitd", "--no-daemon", "--control", "0.0.0.0:8080"]
#CMD ["/usr/local/sbin/start.sh"]
