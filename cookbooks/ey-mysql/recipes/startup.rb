include_recipe "ey-db-ssl::setup"

cookbook_file "/engineyard/bin/mysql_start" do
  source "mysql_start"
  mode "744"
end

ey_cloud_report "report starting mysql" do
  message "starting mysql"
  not_if "/etc/init.d/mysql status"
end

execute "start-mysql" do
  sleeptime = 15      # check mysql's status every 15 seconds
  sleeplimit = 7200   # give mysql 2 hours to start (for long recovery operations)

  command "/engineyard/bin/mysql_start --password #{node.engineyard.environment['db_admin_password']} --check #{sleeptime} --timeout #{sleeplimit}"

  timeout sleeplimit

  not_if "/etc/init.d/mysql status"
end

service "mysql" do
  provider Chef::Provider::Service::Systemd
  action :enable
end

if node["mysql"]["short_version"] == "8.0"
  service "mysql" do
    action :restart
    not_if { ::File.exist?("/db/mysql/8.0/data/mysql.ibd") }
  end
end
