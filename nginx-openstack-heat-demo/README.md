# Deploying and reconfiguring NGINX Plus in OpenStack using Heat

This demo shows how to deploy and configure NGINX Plus to load balance a simple
web application in OpenStack using Heat. It also shows how NGINX Plus can be reconfigured so that
whenever we scale the application by creating or deleting application instances (backends), NGINX Plus gets automatically reconfigured.

You can run this demo in your existing OpenStack environment, provided that you environment has Heat
service enabled. Or you can create a local Devstack setup and we provided instructions below that
will help you create it.

Note that to simplify things, we don't use Neutron.

In the demo steps we'll assume you're using a local Devstack setup.

To be able to install NGINX Plus, you must have a license. If you don’t have one, you can sign up for a [free 30-day trial](https://www.nginx.com/#free-trial).

You can learn more about the approach used in this demo in the blogpost [here](https://developer.rackspace.com/blog/openstack-orchestration-in-depth-part-4-scaling/) at Rackspace.

## Creating a local single-VM OpenStack setup

1. Create a VM with the Ubuntu 14.04 server.
	Successful testing was done on the VM created in VMWare Fusion
	with the following configuration of the VM:
	* 8G RAM
	* 4 cores 
	* 100G hard drive
	* VT-x/EPT enabled in VM settings

	In your hypervisor create a private network and connect the machine to the private network. In this demo we use a private 192.168.100.0/24 network.

	We'll assume our VM is configured with the static IP address 192.168.100.30

1. Install the devstack:
	1. ssh into the machine.

	1. Make sure your Linux user is allowed to use sudo without prompting for a password

	1. Clone the devstack repo:
		```
		$ git clone https://git.openstack.org/openstack-dev/devstack
		```

	1. Go to the `devstack` folder:
		```
		$ cd devstack/
		```

	1. Checkout the stable branch:
		```
		$ git checkout stable/mitaka
		```

	1. Transfer the `local.conf` file from the `devstack` folder to the `devstack` folder on the machine.

	1. Start the devstack:
		```
		$ ./stack.sh
		```
		This step takes a while (20 minutes or more)

	1.  In a browser go to http://192.168.100.30 You should see the Horizon dashboard. You should be able
	to login with 'admin/admin' or demo/admin credentials.


## Launching the demo

We'll create two images for our NGINX Plus and backend VMs that we're going to launch in this demo.
The images will be created with already installed and configured software.

1. Put the NGINX Plus license files -- 'nginx-repo.crt' and 
`nginx-repo.key` -- into the `nginxplus` folder.

1. Transfer the demo files to the VM with Devstack

1. Create the trusty image we'll use as the base image for our images:

	From the `devstack` folder login as admin into the the OpenStack command-line tools:
	```
	$ source openrc admin
	```

	Create the image:
	```
	$ glance --os-image-api-version 1 image-create --name trusty \
--disk-format qcow2 \
--container-format bare \
--location "https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img" \
--min-disk 4 \
--min-ram 512 \
--is-public True
	```

1. Create a flavor for NGINX Plus and backend instances with 512MB RAM and 8G root disk:
	```
	$ nova flavor-create demo_flavor auto 512 8 1
	```	

1. Create a private key that we're going to tell Heat to add to the instances we'll launch. This way
we'll be able to ssh into the instances if we need.
	From the `devstack` folder authenticate login as demo user into the the OpenStack command-line tools:
	```
	$ source openrc demo
	```
	```
	$ openstack keypair create heat_key > heat_key.priv
	$ chmod 600 heat_key.priv
	```

1. Create an NGINX Plus instance:
	Go to the `nginxplus` folder of the demo files folder:
	```
	$ cd nginx-openstack-heat-demo/nginxplus
	```

	Create the stack from the template file specifying the flavor parameter.
	```
	$ heat stack-create -f nginxplus.yaml nginxplus_stack -P flavor=demo_flavor
	```	

	To see that the stack was created, use the following command too check its status.
	Make sure the status is CREATE_COMPLETE before moving to the next step:
	```
	$ heat stack-show nginxplus_stack
	```

1. Create an NGINX Plus image by taking a snapshot of the NGINX Plus instance. Replace <nginxplus_instance-name> with the NGINX Plus instance name. 
You can get the name from the output of the previous command:
	```
	$ nova image-create <nginxplus_instance-name> nginxplus_image
	```

1. Delete the NGINX Plus stack. This removes the instance:
	```
	$ heat stack-delete nginxplus_stack
	```

1. Create a backend instance:
	Go to the backend folder:
	```
	$ cd ../backend
	```

	Create the stack from the template file specifying the flavor argument.
	```
	$ heat stack-create -f backend.yaml backend_stack -P flavor=demo_flavor
	```

	To see that the stack was created, use the command below to check its status.
	Make sure the status is CREATE_COMPLETE before moving the next step:
	```
	$ heat stack-show backend_stack 
	```

1. Create a backend image by taking a snapshot of the backend instance. Replace <backend_instance_name> with the backend instance name. You can get the name from the output of the previous command.
	```
	$ nova image-create <backend_instance> backend_image
	```

1. Delete the backend stack:
	```
	$ heat stack-delete backend_stack
	```

1. Create a nova security group for NGINX Plus:
	```
	$ nova secgroup-create nginxplus_sg "allow http and http-alt"
	$ nova secgroup-add-rule nginxplus_sg tcp 80 80 0.0.0.0/0
	$ nova secgroup-add-rule nginxplus_sg tcp 8080 8080 0.0.0.0/0
	```

1. Create the demo stack:
	Cd to the nginx-openstack-heat-demo folder:
	```
	$ cd ..
	```

	Create the stack from the template file. Specify two parameters, flavor and most importantly
	backend_count, which defines how many backend instances Heat will launch.
	```
	$ heat stack-create -f demo.yaml demo_stack -P 'flavor=demo_flavor;backend_count=3'
	```

	To check the status of the stack run:
	```
	$ heat stack-list
	```

	Remember the floating IP of the NGINX Plus instance from the output of the previous command.

1. To access the NGINX Plus instance from the local machine add a route to a public network with
the Devstack VM as a gateway. In case if your host machine is a machine with OSX, you can run:
	```
	$ sudo route add 172.24.4.0/24 192.168.100.30
	```

1. To connect to the web application, open a browser and enter the public floating IP of the NGINX Plus instance. You should be able to see a page that tells from which backend it came. Every time time you refresh the page, the response will come from different backend.

1. In a browser open the NGINX Plus live-activity monitoring dashboard. It's available on port 8080 of the load 
balancer. On the Upstreams tab you'll see that all the backends were added to the NGINX Plus.

1. Scale the application up. We update the stack with the new value for the backend_count parameters:
	```
	$ heat stack-update demo_stack_10 -f demo.yaml -P 'flavor=demo_flavor;backend_count=6'
	```
	In the dashboard you'll see that new backends were added.

1. Scale the application down.
	```
	$ heat stack-update demo_stack_10 -f demo.yaml -P 'flavor=demo_flavor;backend_count=1'
	```
