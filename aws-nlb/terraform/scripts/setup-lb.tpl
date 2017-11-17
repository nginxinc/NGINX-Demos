#!/bin/sh

cat > /etc/nginx/conf.d/default.conf <<EOF
upstream app1 {
  server ${ngx-oss-app1-1-ip};
  server ${ngx-oss-app1-2-ip};
  zone app1 64k;
}

upstream app2 {
  server ${ngx-oss-app2-1-ip};
  server ${ngx-oss-app2-2-ip};
  zone app2 64k;
}

server {
  listen 80;

  status_zone backend;

  root /usr/share/nginx/html;

  location / {
  }

  location /backend-one {
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_pass http://app1/;
  }

  location /backend-two {
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_pass http://app2/;
  }

  location = /status.html {
  }

  location /status {
    access_log off;
    status;
  }
}
EOF

nginx -s reload
