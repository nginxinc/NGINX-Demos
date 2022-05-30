# First Demo

In this demo we will deploy a simple web application and then configure load balancing using the Kubernetes [built-in TCP/UDP load balancing](http://kubernetes.io/docs/user-guide/services/#type-loadbalancer). The demo works only if you run  your Kubernetes cluster in a supported cloud provider.

## Running the Demo

1. List the nodes of the cluster:
  ```
  $ kubectl get nodes
  ```

1. Deploy two containers (pods) of a simple web application that returns a page with information about the container it is deployed on:
  ```
  $ kubectl run hello-app --image=nginxdemos/hello --port=80 --replicas=2
  ```
1. Check if containers were created:
  ```
  $ kubectl get pods -o wide
  ```
1. Configure external load balancing for the application:
  ```
  $ kubectl expose pod hello-app --type="LoadBalancer"
  ```
  This steps allocates a cloud load balancer that gets configured to load balance our application. It works only if you run your Kubernetes cluster in a supported cloud provider.

1. Get the IP address of the allocated cloud load balancer:
  ```
  $ kubectl get svc hello-app
  ```

1. Make HTTP requests to the application using the IP address obtained in the previous step.
