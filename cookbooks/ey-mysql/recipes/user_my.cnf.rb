#
# Cookbook:: mysql
# Recipe:: user_my.cnf.rb
#
# Copyright:: 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
ey_cloud_report "db user config" do
  message "setting up user configuration started"
end

template "/root/.my.cnf" do
  owner "root"
  mode "600"
  variables({
    username: node.engineyard.environment["db_admin_username"],
    password: node.engineyard.environment["db_admin_password"],
    home_dir: "/root/",
    mysql_version: Gem::Version.new(node["mysql"]["short_version"]),
    mysql_5_7: Gem::Version.new("5.7"),
    host: node["dna"]["instance_role"][/^(db|solo)/] ? "localhost" : node["dna"]["db_host"],
    is_rds: db_host_is_rds?,
  })
  source "user_my.cnf.erb"
end

template "/home/#{node['owner_name']}/.my.cnf" do
  owner node["owner_name"]
  mode "600"
  variables({
    username: node["owner_name"],
    password: node["owner_pass"],
    home_dir: "/home/#{node['owner_name']}/",
    mysql_version: Gem::Version.new(node["mysql"]["short_version"]),
    mysql_5_7: Gem::Version.new("5.7"),
    host: node["dna"]["instance_role"][/^(db|solo)/] ? "localhost" : node["dna"]["db_host"],
    is_rds: db_host_is_rds?,
  })
  source "user_my.cnf.erb"
end

ey_cloud_report "db user config" do
  message "setting up user configuration finished"
end