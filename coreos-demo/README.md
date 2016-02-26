# Load Balancing Applications with NGINX Plus in a CoreOS Cluster

The demo shows how to load balance a web application running in a CoreOS cluster
with NGINX Plus.

To run the demo you need have a CoreOS cluster:

* You can use our automated Vagrant setup, described below, to create a CoreOS cluster locally. Each machine will have the required files copied to it and be ready for the demo.
* Run the demo in your existing CoreOS cluster. Make sure:
  * The cluster has at least 4 machines
  * To copy the template unit files to one of the machine of
  your CoreOS cluster
  * To have the NGINX Plus Docker image available on *each* machine.


The project accompanies the [blog post](https://www.nginx.com/blog/load-balancing-applications-nginx-plus-coreos-cluster/) that provides more details and instructions.

## Automated Vagrant Setup

### Prerequisites

The following software must be installed on your machine:

1. [git](https://git-scm.com/).
1. [Vagrant](https://www.vagrantup.com/).

You must also have an NGINX Plus license. If you don’t have one, you can sign up for a [free 30-day trial](https://www.nginx.com/#free-trial).


Please note that the demo creates 4 virtual machines with 1GB of RAM each.

### Setting Up Cluster

1. Clone the repo:
  ```
  $ git clone https://github.com/nginxinc/NGINX-Demos.git
  ```

1. Go to the ```coreos``` folder:
  ```
  $ cd NGINX-Demos/coreos
  ```

1. Create the ```user-data``` file by copying the ```user-data.sample``` file:
  ```
  $ cp user-data.sample user-data
  ```

1. Copy the ```nginx-repo.crt``` and ```nginx-repo.key``` files of your NGINX Plus license to the ```nginxplus-coreos``` folder.

1. Create and start virtual machines:
  ```
  $ vagrant up
  ```
  A cluster with 4 machines will be created. This step might take a while. As you might notice from the output, we make the NGINX Plus Docker image available on each machine by building the image on each machine.


1. Add the Vagrant key to the ssh-agent:
  ```
  $ ssh-add ~/.vagrant.d/insecure_private_key
  ```

1. Ssh into the first machine:
  ```
  $ vagrant ssh core-01 -- -A
  ```

1. Make sure that each machine is up and running:
  ```
  $ fleetctl list-machines
  MACHINE		IP		METADATA
  8fc15e4c...	172.17.8.101	-
  c99a2e16...	172.17.8.104	-
  f7462d7a...	172.17.8.102	-
  f7672f06...	172.17.8.103	-
  ```

## Running the Demo

**Note**: This is a short version of the demo. The full version is available in the [blog post](https://www.nginx.com/blog/load-balancing-applications-nginx-plus-coreos-cluster/).

In our Vagrant setup unit files are located in the ```/home/core/unit-files``` folder.

1. We've already sshed into the first machine. Let's go to the ```unit-files``` folder:
  ```
  $ cd unit-files
  ```

1. Let's start 3 backend units with 3 corresponding service discovery units:
  ```
  $ fleetctl start backend@1 && fleetctl start backend-discovery@1
  $ fleetctl start backend@2 && fleetctl start backend-discovery@2
  $ fleetctl start backend@3 && fleetctl start backend-discovery@3
  ```

1. Let's start 1 load balancer unit with 1 corresponding service discovery unit:
  ```
  $ fleetctl start loadbalancer@1 && fleetctl start loadbalancer-discovery@1
  Unit loadbalancer@1.service inactive
  Unit loadbalancer@1.service launched on f7672f06.../172.17.8.103
  Unit loadbalancer-discovery@1.service inactive
  Unit loadbalancer-discovery@1.service launched on f7672f06.../172.17.8.103
  ```

  As you can see from the output, the units were launched on the machine with the IP address of ```172.17.8.103```.

1. Let's make a request to the load balancer:
  ```
  $ curl 172.17.8.103
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
  <h2>My hostname is 167be74cb44a</h2>
  <h2>My address is 10.1.99.2:80</h2>
  </body>
  </html>
  ```
We got the response from one of the backends.

1. Check the NGINX Plus Status page, which is in our case available at http://172.17.8.103:8081/status.html.

1. Using the Status API, we can list all the servers of our backend:
  ```
  $ curl -s 172.17.8.103:8081/status |  jq '.upstreams.backend.peers[] | {server: .server, state: .state}'
  {
    "server": "172.17.8.101:8080",
    "state": "up"
  }
  {
    "server": "172.17.8.104:8080",
    "state": "up"
  }
  {
    "server": "172.17.8.102:8080",
    "state": "up"
  }
  ```


## Links

1. For more information about the demo see the [blog post](https://www.nginx.com/blog/load-balancing-applications-nginx-plus-coreos-cluster/).
1. For details on how to create a CoreOS cluster with Vargant, see [CoreOS documentation](https://coreos.com/blog/coreos-clustering-with-vagrant/).
