
# Cookbook Name:: ey-le
# Recipe:: start
#

# Restart the le agent
service 'logentries' do
  action [:enable, :restart]
end
