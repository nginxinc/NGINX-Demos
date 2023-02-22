FROM debian:bullseye-slim

ARG NMS_URL
ARG DEVPORTAL=false
ARG NAP_WAF=false

# Initial packages setup
RUN	apt-get -y update \
	&& apt-get -y install -y apt-transport-https lsb-release ca-certificates wget gnupg2 wget curl \
# NGINX Instance Manager agent setup
	&& mkdir -p /deployment /etc/ssl/nginx \
# Agent installation
	&& bash -c 'curl -k $NMS_URL/install/nginx-agent | sh' && echo "Agent installed from NMS"

# Startup script
COPY ./container/start.sh /deployment/

# Download certificate and key from the customer portal (https://account.f5.com)
# and copy to the build context
RUN --mount=type=secret,id=nginx-crt,dst=/etc/ssl/nginx/nginx-repo.crt,mode=0644 \
	--mount=type=secret,id=nginx-key,dst=/etc/ssl/nginx/nginx-repo.key,mode=0644 \
	set -x \
# Startup script
	&& chmod +x /deployment/start.sh && touch /.dockerenv \
# Install prerequisite packages:
	&& apt-get -y update \
	&& apt-get -y install apt-transport-https lsb-release ca-certificates wget gnupg2 debian-archive-keyring \
	&& wget -qO - https://cs.nginx.com/static/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null \
	&& printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://pkgs.nginx.com/plus/debian `lsb_release -cs` nginx-plus\n" | tee /etc/apt/sources.list.d/nginx-plus.list \
	&& wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90pkgs-nginx \
	&& apt-get -y update \
	&& apt-get -y install nginx-plus nginx-plus-module-njs nginx-plus-module-prometheus \

# Optional NGINX App Protect WAF
	&& if [ "$NAP_WAF" = "true" ] ; then \
	wget -qO - https://cs.nginx.com/static/keys/app-protect-security-updates.key | gpg --dearmor | tee /usr/share/keyrings/app-protect-security-updates.gpg >/dev/null \
	&& printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://pkgs.nginx.com/app-protect/debian `lsb_release -cs` nginx-plus\n" | tee /etc/apt/sources.list.d/nginx-app-protect.list \
	&& printf "deb [signed-by=/usr/share/keyrings/app-protect-security-updates.gpg] https://pkgs.nginx.com/app-protect-security-updates/debian `lsb_release -cs` nginx-plus\n" | tee -a /etc/apt/sources.list.d/nginx-app-protect.list \
	&& apt-get -y update \
	&& apt-get -y install app-protect app-protect-attack-signatures; fi \

# Optional API Connectivity Manager DevPortal
# https://docs.nginx.com/nginx-management-suite/admin-guides/installation/on-prem/install-guide/
	&& if [ "$DEVPORTAL" = "true" ] ; then \
	printf "deb https://pkgs.nginx.com/nms/debian `lsb_release -cs` nginx-plus\n" | tee /etc/apt/sources.list.d/nms.list \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 \
	&& apt-get -y update \
	&& apt-get -y install nginx-devportal nginx-devportal-ui \
	&& echo 'DB_TYPE="sqlite"' | tee -a /etc/nginx-devportal/devportal.conf \
	&& echo 'DB_PATH="/var/lib/nginx-devportal"' | tee -a /etc/nginx-devportal/devportal.conf; fi \

# Forward request logs to Docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80
STOPSIGNAL SIGTERM

CMD /deployment/start.sh
