FROM nginx/unit:latest

COPY start.sh /usr/local/sbin
RUN chmod +x /usr/local/sbin/start.sh

RUN apt-get update

# For testing purposes - can be removed if desired
RUN apt-get install -y procps net-tools

RUN apt-get install -y apt-transport-https curl wget
RUN apt-get install -y php7.0-curl
RUN apt-get install -y stress

EXPOSE 8443 9080

STOPSIGNAL SIGTERM

CMD ["/usr/local/sbin/start.sh"]
