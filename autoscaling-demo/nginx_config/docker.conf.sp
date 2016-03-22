upstream nginx_backends {
    zone nginx_backends 64K;
    state /tmp/nginx_backends.state;
    sticky cookie test;
}

upstream elasticsearch_backends {
    zone elasticsearch_backends 64K;
    state /tmp/elasticsearch_backends.state;
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
    location /upstream_conf {
        upstream_conf;
    }
}

server {
    listen 9200;
    status_zone elasticsearch;
    location / {
        proxy_pass http://elasticsearch_backends;
        proxy_connect_timeout 1s;
        proxy_read_timeout 1s;
        #proxy_next_upstream error timeout;
        #health_check uri=/_cat/indices?v;
    }
}

server {
    listen 8080;
    root /usr/share/nginx/html;
 
    location / {
        index status.html;
    }

    location = /status.html {
    }

    location /status {
        status;
    }
}


