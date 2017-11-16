# See http://docs.chef.io/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                ""
client_key               "#{current_dir}/<>.pem"
chef_server_url          "https://api.chef.io/organizations/nginx"
cookbook_path            ["#{current_dir}/../cookbooks"]
#AWS variables
knife[:aws_access_key_id] = ""
knife[:aws_secret_access_key] = ""
knife[:region] = "us-west-2"
#openstack variables
knife[:openstack_auth_url] = "http://192.168.111.128:5000/v2.0/tokens"
knife[:openstack_username] = "admin"
knife[:openstack_password] = "nomoresecret"
knife[:openstack_tenant] = "admin"
knife[:openstack_flavor] = "10"
knife[:openstack_image] = "416f5135-47c4-4408-a44f-1e2d8c9ebbf6"
knife[:openstack_ssh_key_id] = "demo_key"
