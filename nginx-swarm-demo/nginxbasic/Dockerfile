FROM nginx

# copy the cert and key
COPY swarmdemo.crt /root
COPY swarmdemo.key /root

# copy the config files
RUN rm /etc/nginx/conf.d/*
COPY backend.conf /etc/nginx/conf.d/
