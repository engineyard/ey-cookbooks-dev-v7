require "pp"
#
# Cookbook:: ey-memcached-custom
# Recipe:: install
#

# memcached_download_url = node["memcached"]["download_url"]
# memcached_installer_directory = "/opt/memcached-installer"

ey_cloud_report "memcached" do
  message "Installing memcached"
end

Chef::Log.info "INSTALL TYPE: #{node['memcached']['install_type']}"
Chef::Log.info "INSTANCE ROLE: #{node['dna']['instance_role']}"
Chef::Log.info "UTILITY NAME: #{node['memcached']['utility_name']}"

is_memcached_instance = case node["memcached"]["install_type"]
                        when "ALL_APP_INSTANCES"
                          ["solo", "app_master", "app"].include?(node["dna"]["instance_role"])
                        else
                          (node["dna"]["instance_role"] == "util") && (node["dna"]["name"] == node["memcached"]["utility_name"])
                        end

if is_memcached_instance
  template "/etc/memcached.conf" do
    source "memcached.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables memusage: node["memcached"]["memusage"],
      port: 11211,
      misc_opts: node["memcached"]["misc_opts"]
  end

  if node["memcached"]["install_from_source"]
    include_recipe "ey-memcached::install_from_source"
  else
    file "/etc/systemd/system/memcached.service" do
      action :delete
      only_if "grep /usr/local/share/memcached/scripts/systemd-memcached-wrapper /etc/systemd/system/memcached.service"
    end
    include_recipe "ey-memcached::install_from_package"
  end

  service "memcached" do
    provider Chef::Provider::Service::Systemd
    action :enable
  end

end
