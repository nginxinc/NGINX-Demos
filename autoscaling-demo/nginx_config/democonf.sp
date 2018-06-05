upstream nginx_backends {
    zone nginx_backends 64K;
    state /tmp/nginx_backends.state;
    sticky cookie test;
}

upstream unit_backends {
    zone unit_backends 64K;
    state /tmp/unit_backends.state;
}

match server_ok {
    status 200;
    body ~ "Status: OK";
}

server {
    listen 80;
    status_zone nginx_ws;
    location / {
        proxy_pass http://nginx_backends;
        sub_filter '<!--IP-->' "$upstream_addr";
        sub_filter_once on; 
        health_check uri=/healthcheck.html match=server_ok;
    }
}

server {
    listen 9080;
    status_zone unit;
    location / {
        proxy_pass http://unit_backends;
    }
}

server {
    listen 8080;
    root /usr/share/nginx/html;
 
    location / {
        index dashboard.html;
    }

    location /api {
        api write=on;
    }

}


