include_recipe 'nginx::opensource'

service 'nginx' do
  supports status: true, restart: true, reload: true
  action   :enable
end

cookbook_file '/usr/share/nginx/html/index.html' do
  source 'hello-index.html'
  owner 'root'
  group node['root_group']
  mode 0644
end

template '/etc/nginx/conf.d/hello.conf' do
  source 'hello.conf.erb'
  owner 'root'
  group node['root_group']
  mode 0644
  notifies :reload, 'service[nginx]', :delayed
end

directory '/etc/nginx/sites-enabled' do
  recursive true
  action :delete
  notifies :reload, 'service[nginx]', :delayed
end

directory '/etc/nginx/sites-available' do
  recursive true
  action :delete
  notifies :reload, 'service[nginx]', :delayed
end
