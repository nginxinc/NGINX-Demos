#!/bin/sh
cat > /tmp/default.conf <<EOF
upstream app_one {
  zone app_one 64k;
  state /var/lib/nginx/state/app_one.conf;
}

upstream app_two {
  zone app_two 64k;
  state /var/lib/nginx/state/app_two.conf;
}

server {
  listen 80;

  status_zone app;

  location / {
    root /usr/share/nginx/html;
  }

  location ~ /favicon.ico {
    root /usr/share/nginx/images;
  }

  location /app_one {
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_pass http://app_one/;
  }

  location /app_two {
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_pass http://app_two/;
  }
}

server {
  listen 8080;

  location /api {
    api write=on;
  }

  location = /dashboard.html {
    root /usr/share/nginx/html;
  }
}
EOF

sudo mv /tmp/default.conf /etc/nginx/conf.d/default.conf
sudo nginx -s reload
