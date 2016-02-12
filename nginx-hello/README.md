
# NGINX webserver that serves a simple page containing its hostname, IP address and port.

The image is uploaded to Docker Hub -- https://hub.docker.com/r/nginxdemos/hello/

How to run:
```
$ docker run -P -d nginxdemos/hello
```

Now, assuming we found out the IP address and the port that mapped to port 80 of the container and put them into 
the variables ```$HELLO_IP``` and ```$HELLO_PORT```, we can run:
```
$ curl $HELLO_IP:$HELLO_PORT
<!DOCTYPE html>
<html>
<head>
<title>Hello from NGINX!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Hello!</h1>
<h2>My hostname is 5f41bf822960</h2>
<h2>My address is 172.17.0.2:80</h2>
</body>
</html>
```

We get the value of a hostname from NGINX [hostname](http://nginx.org/en/docs/http/ngx_http_core_module.html#var_hostname) variable
and the value of an address by combining [server_addr](http://nginx.org/en/docs/http/ngx_http_core_module.html#var_server_addr) and 
[server_port](http://nginx.org/en/docs/http/ngx_http_core_module.html#var_server_port) variables.


The image was created to be used as a simple backend for various load balancing demos.
