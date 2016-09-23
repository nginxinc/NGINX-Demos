FROM nginx

# copy the cert and key
COPY swarmdemo.selfcrt /root/swarmdemo.crt
COPY swarmdemo.selfkey /root/swarmdemo.key

# copy the config files
RUN rm /etc/nginx/conf.d/*
COPY backend.conf /etc/nginx/conf.d/
