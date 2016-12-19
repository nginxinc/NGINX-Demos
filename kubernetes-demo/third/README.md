# Third demo

In this demo we will configure load balancing for the cafe application from the second demo. However, we won’t use the Ingress controller. By ourselves, we will create the NGINX configuration and then deploy the NGINX Plus image with that configuration. Deploying NGINX Plus this way without the Ingress controller  gives us great flexibility and allows us to use all of the NGINX advanced features. It allows us to support any advanced use cases that are not available with Ingress.

To configure NGINX Plus we utilize the [DNS-based service discovery with DNS SRV (Service) records](https://www.nginx.com/blog/dns-service-discovery-nginx-plus/) available in NGINX Plus. Read the [Load Balancing Kubernetes Services with NGINX Plus](https://www.nginx.com/blog/load-balancing-kubernetes-services-nginx-plus/) blog post on the details of such configuration for Kubernetes.

## Prerequisites

You must have the NGINX Plus subscription. If you don't have one, you can sign up for a [free 30-day trial](https://www.nginx.com/free-trial-request/). Place the key (`nginx-repo.key`) and the certificate (`nginx-repo.crt`) files of your subscription into the `nginxplus` folder.

## Running the demo

1. Build the NGINX Plus Docker image:
  ```
  $ cd nginxplus/
  $ docker build -t nginxplus .
  ```

1. Make the nginxplus image available to the nodes of your cluster. For example, you can push it to a private Docker registry.

1. Create the replications controllers of the cafe application:
  ```
  $ kubectl create -f tea-rc.yaml
  $ kubectl create -f coffee-rc.yaml
  ```

1. Checks that the pods were created:
  ```
  $ kubectl get pods
  ```

1. Create the services of the cafe application:
  ```
  $ kubectl create -f tea-svc.yaml
  $ kubectl create -f coffee-svc.yaml
  ```

1. Deploy the NGINX Plus replication controller:
  ```
  $ kubectl create -f nginxplus-rc.yaml
  ```
  Before running this step, make necessary changes to the `nginxplus-rc.yaml` file: edit line 18 to specify your private Docker registry, to which you pushed the nginxplus image.

1. Check that the nginxplus pod was created:
  ```
  $ kubectl get pods
  ```

1. Get the external IP address of the node, at which the NGINX Plus pod is running:
  ```
  $ kubectl get pods -o wide | grep nginx | awk '{print $6}' | xargs kubectl get node -o json | grep ExternalIP -A 2
  ```

1. Using the IP address obtained in the previous step make HTTP requests to the cafe application:
  1. Use the `/tea` URL to get to the tea service.
  1. Use the `/coffee` URL to get to the coffee service.

1. Connect to the [live-activity monitoring dashboard](https://www.nginx.com/products/live-activity-monitoring/), available at port 8080. Use the IP address obtained from the step before the previous one.

1. Scale the coffee service from 3 pods to 5 pods:
  ```
  $ kubectl scale rc coffee-rc --replicas=5
  ```

1. See that the new pods of the coffee service were added to the load balancer by looking the at live-activity monitoring dashboard.
