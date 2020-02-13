# NGINX Ingress Controller Demo

This demo shows the new NGINX Ingress Resources (VirtualServer and VirtualServerRoute) of NGINX Ingress Controller in action and compares them with the Kubernetes Ingress resource.

## Prerequistes 

* Get access to a Kubernetes cluster in a cloud.
* Install the NGINX Plus Ingress Controller. See https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/ 
    * As part of the installation mentioned above, make sure to expose the Ingress Controller through the service of the type LoadBalancer, so that you get a public IP through which you will be able to access the Ingress Controller.
    * For convenience, add the following two lines to your `/etc/hosts/` file:
        ```
        <public-ip>  cafe.example.com
        <public-ip>  cafe-ing.example.com
        ```
        where `<public-ip>` is the public IP of the Ingress Controller.
* *Optional*. The backend apps are published at the `pleshakov` Docker registry on DockerHub. You can push them to your Docker registry. The sources are in the `apps` folder.


## Steps

### Deploy Backend Apps 

1. Clone the repo and cd into the `k8s` folder:
    ```
    $ git clone https://github.com/nginxinc/NGINX-Demos
    $ cd NGINX-Demos/kubernetes-demo-nginx-ingress-resources/k8s
    ```
1. Deploy the backend apps (`tea`, `coffee` and `coffee-decaf`) and check that they are running:
    ```
    $ kubectl apply -f apps.yaml
    ```
    ```
    $ kubectl get pods,svc
    NAME                                READY   STATUS              RESTARTS   AGE
    pod/coffee-775f8b68b-gpd4b          1/1     Running             0          9s
    pod/coffee-775f8b68b-vmqjz          1/1     Running             0          9s
    pod/coffee-decaf-67d7944669-4ntrm   1/1     Running             0          9s
    pod/coffee-decaf-67d7944669-sqvfp   0/1     ContainerCreating   0          9s
    pod/tea-5cdb7f8bbb-6nctr            1/1     Running             0          9s

    NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
    service/coffee-decaf-svc   ClusterIP   10.114.5.28     <none>        80/TCP    9s
    service/coffee-svc         ClusterIP   10.114.15.166   <none>        80/TCP    9s
    service/tea-svc            ClusterIP   10.114.13.28    <none>        80/TCP    9s
    ```

1. Create a namespace `special`:
    ```
    $ kubectl create namespace special
    ```
1. Deploy the special coffee app in the the special namespace and check that it's running:
    ```
    $ kubectl apply -f apps-special-ns.yaml
    ```
    ```
    $ kubectl get pods,svc -n special
    NAME                                  READY   STATUS    RESTARTS   AGE
    pod/coffee-special-548865b485-2phmt   1/1     Running   0          8s
    pod/coffee-special-548865b485-f8cgl   1/1     Running   0          8s

    NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
    service/coffee-special-svc   ClusterIP   10.114.12.233   <none>        80/TCP    8s
    ```

### Configure Load Balancing

1. Deploy a Secret with TLS cert and key for TLS termination: 
    ```
    $ kubectl apply -f cafe-ingress.yaml
    ```

1. Deploy an Ingress resource:
    ```
    $ kubectl apply -f cafe-secret.yaml
    ```

1. Deploy a VirtualServer and a VirtualServerRoute resources: 
    ```
    $ kubectl apply -f cafe-virtual-server.yaml
    $ kubectl apply -f coffee-virtual-server-route.yaml
    ```

### Test Load Balancing

#### Ingress Resource

Prefix-based routing:
1. Send a request to the coffee app -- https://cafe-ing.example.com/coffee
1. Send a request to the tea app -- https://cafe-ing.example.com/tea

#### VirtualServer

Prefix-based routing:
1. Send a request to the coffee app -- https://cafe.example.com/coffee
1. Send a request to the tea app -- https://cafe.example.com/tea

Traffic splitting:
1. Send a request with to https://cafe.example.com/coffee-split Expect a 50/50 distribution between regular and decaf coffee apps.

Routing based on an URL argument:
1. Send a request to https://cafe.example.com/coffee-argument Expect a response from the regular coffee app.
1. Send a request to https://cafe.example.com/coffee-argument?choice=decaf Expect a response from the decaf coffee app.

Routing based on a regex with a fixed response:
1. Send a request to https://cafe.example.com/blabla-latte-blabla Expect a 404 a response with the "No lattes!" message.

Routing based on an exact match with a redirect response:
1. Send a request to https://cafe.example.com/nginx/something Expect a 404 response from NGINX Ingress Controller.
1. Send a request to https://cafe.example.com/nginx Expect a 302 redirect to https://nginx.org

Routing based on a prefix with delegation:

1. Send a request to https://cafe.example.com/special Expect a response from the special coffee app from the namespace special.

### Connect to the Dashboard

1. Port-forward to the Ingress Controller pod on port 8080  (replace `<nginx-ingress-pod>` with the actual name of a pod):
    ```
    kubectl port-forward <nginx-ingress-pod> 8080:8080 -n nginx-ingress
    ```
1. Open http://127.0.0.1:8080/dashboard.html in the browser to see the dashboard.

### See the Prometheus Metrics 

1. Port-forward to the Ingress Controller pod on port 9113 (replace `<nginx-ingress-pod>` with the actual name of a pod):
    ```
    kubectl port-forward <nginx-ingress-pod> 9113:9113 -n nginx-ingress
    ```
1. Open http://127.0.0.1:9113/metrics in the browser to see the Prometheus metrics.
