#!/bin/sh
sudo wget https://github.com/nginxinc/nginx-asg-sync/releases/download/v0.4-1/nginx-asg-sync-0.4-1.amzn2.x86_64.rpm
sudo yum install nginx-asg-sync-0.4-1.amzn2.x86_64.rpm -y
sudo rm nginx-asg-sync-0.4-1.amzn2.x86_64.rpm

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
    health_check;
  }

  location /app_two {
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_pass http://app_two/;
    health_check;
  }
}

server {
  listen 8080;

  location /api {
    api write=on;
  }

  location /dashboard.html {
    root /usr/share/nginx/html;
  }
}
EOF

sudo mv /tmp/default.conf /etc/nginx/conf.d/default.conf
sudo nginx -s reload

cat > /tmp/config.yaml <<EOF
region: us-west-1
api_endpoint: http://127.0.0.1:8080/api
sync_interval_in_seconds: 1
cloud_provider: AWS
upstreams:
  - name: app_one
    autoscaling_group: ngx-oss-one-autoscaling
    port: 80
    kind: http
    max_conns: 0
    max_fails: 1
    fail_timeout: 10s
    slow_start: 0s
  - name: app_two
    autoscaling_group: ngx-oss-two-autoscaling
    port: 80
    kind: http
    max_conns: 0
    max_fails: 1
    fail_timeout: 10s
    slow_start: 0s
EOF

sudo mv /tmp/config.yaml /etc/nginx/config.yaml
sudo systemctl enable nginx-asg-sync
