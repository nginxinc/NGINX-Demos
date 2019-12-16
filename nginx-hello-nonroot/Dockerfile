FROM nginx:mainline-alpine

RUN chmod -R a+w /var/cache/nginx/ \
        && cat > /var/run/nginx.pid \
        && chmod a+w /var/run/nginx.pid \
        && rm /etc/nginx/conf.d/*

COPY hello-nonroot.conf /etc/nginx/conf.d/
COPY index.html /usr/share/nginx/html/
USER nginx
