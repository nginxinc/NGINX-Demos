
# NGINX webserver that runs with non-root privileges to serve a simple page containing its hostname, IP address and port as well as the request URI and the local time of the webserver.

The images are uploaded to Docker Hub -- https://hub.docker.com/r/nginxdemos/nginx-hello/.

How to run:
```
$ docker run -P -d nginxdemos/nginx-hello
```

Now, assuming we found out the IP address and the port that mapped to port 8080 on the container, in a browser we can make a request to the webserver and get the page below: ![hello](hello.png)

A plain text version of the image is available as `nginxdemos/nginx-hello:plain-text`. This version returns the same information in the plain text format:
```
$ curl <ip>:<port>
Server address: 172.17.0.2:8080
Server name: 46baxda6547e
Date: 02/Jan/2020:13:05:05 +0000
URI: /
Request ID: 64ab3cv564a6ed165e783469c2ae645d
```

The images were created to be used as simple backends for various load balancing demos.
