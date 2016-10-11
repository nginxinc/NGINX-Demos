# Second Demo

In this demo we will configure HTTP load balancing for our sample web application -- the *cafe app*. The cafe app consists of two services: the *tea service* and the *coffee service*. Requests with a URI ending with `/tea` must be handled by our tea service and the ones with a URI ending with `/coffee` -- by our coffee service. All communications with our app must be secured with SSL.

## Running the Demo

Please follow the instructions from the [main example](https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/complete-example) at our NGINX Ingress Controllers GitHub repository.
