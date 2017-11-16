upstream_node_ips = []
upstream_role = (node[:nginx][:upstream]).to_s
search(:node, "role:#{node[:nginx][:upstream]}-upstream") do |nodes|
  host_ip = nodes['ipaddress']
  unless host_ip.to_s.strip.empty?
    host_port = nodes['nginx']['application_port']
    upstream_node_ips << "#{host_ip}:#{host_port}" # if value.has_key?("broadcast")
  end
end

template "/etc/nginx/conf.d/#{node[:nginx][:upstream]}-upstream.conf" do
  source 'upstreams.conf.erb'
  owner 'root'
  group node['root_group']
  mode 0644
  variables(
    hosts: upstream_node_ips
  )
  # notifies :reload, 'service[nginx]', :delayed
  notifies :run, 'execute[run_api_update_script]', :delayed
end

template "/etc/nginx/conf.d/#{node[:nginx][:server_name]}.conf" do
  source 'server.conf.erb'
  owner 'root'
  group node['root_group']
  mode 0644
  notifies :reload, 'service[nginx]', :delayed
end

package 'jq' do
  action :install
end

template '/tmp/api_update.sh' do
  source 'api_update.sh.erb'
  owner 'root'
  group node['root_group']
  mode 0755
  variables(
    node_ips: upstream_node_ips
  )
end

execute 'run_api_update_script' do
  command '/bin/bash /tmp/api_update.sh'
  # action :nothing
end
