FROM debian:bullseye-slim

ARG NMS_URL
ARG NAP_WAF=false

# Initial packages setup
RUN	apt-get -y update \
	&& apt-get -y install apt-transport-https lsb-release ca-certificates wget gnupg2 curl debian-archive-keyring iproute2 \
	&& mkdir -p /deployment /etc/ssl/nginx \
	&& addgroup --system --gid 20983 nginx \
	&& adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 20983 nginx

# Use certificate and key from kubernetes secret
RUN --mount=type=secret,id=nginx-crt,dst=/etc/ssl/nginx/nginx-repo.crt,mode=0644 \
	--mount=type=secret,id=nginx-key,dst=/etc/ssl/nginx/nginx-repo.key,mode=0644 \
	set -x \
# Install prerequisite packages:
	&& wget -qO - https://cs.nginx.com/static/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg \
	&& printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://pkgs.nginx.com/plus/debian `lsb_release -cs` nginx-plus\n" > /etc/apt/sources.list.d/nginx-plus.list \
	&& wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90pkgs-nginx \
	&& apt-get -y update \
	&& apt-get -y install nginx-plus nginx-plus-module-njs nginx-plus-module-prometheus \

# Optional NGINX App Protect WAF
	&& if [ "$NAP_WAF" = "true" ] ; then \
	wget -qO - https://cs.nginx.com/static/keys/app-protect-security-updates.key | gpg --dearmor > /usr/share/keyrings/app-protect-security-updates.gpg \
	&& printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://pkgs.nginx.com/app-protect/debian `lsb_release -cs` nginx-plus\n" > /etc/apt/sources.list.d/nginx-app-protect.list \
	&& printf "deb [signed-by=/usr/share/keyrings/app-protect-security-updates.gpg] https://pkgs.nginx.com/app-protect-security-updates/debian `lsb_release -cs` nginx-plus\n" >> /etc/apt/sources.list.d/nginx-app-protect.list \
	&& apt-get -y update \
	&& apt-get -y install app-protect app-protect-attack-signatures; fi \

# Forward request logs to Docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \

	&& groupadd -g 1001 nginx-agent \
	&& usermod root -G nginx-agent \
	&& usermod nginx -G nginx-agent \

# NGINX Instance Manager agent installation
	&& bash -c 'curl -k $NMS_URL/install/nginx-agent | sh' && echo "Agent installed from NMS"

# Startup script
COPY ./container/start.sh /deployment/
RUN	chmod +x /deployment/start.sh && touch /.dockerenv


EXPOSE 80
STOPSIGNAL SIGTERM

CMD /deployment/start.sh
