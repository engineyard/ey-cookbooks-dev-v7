include_recipe "ey-db_admin_tools"

if db_host_is_rds? && node.engineyard.environment[:db_stack_name][/^(mysql\d+|aurora\d+)/]
  include_recipe "ey-mysql::setup_app_users_dbs"
end

include_recipe "ey-ebs::default"
innodb_buff = calc_innodb_buffer_pool()

ey_cloud_report "mysql config" do
  message "mysql config and dir creation started"
end

if node.engineyard.instance.arch_type == "arm64"
  raise "Graviton instances are not supported for MySQL currently!"
end

# these are both 32-bit unique values, so why not?
require "ipaddr"
private_ip = node["ec2"]["local_ipv4"]
server_id = IPAddr.new(private_ip).to_i

bash "adjust-mysql-server-id" do
  code <<-EOH
    config_server_id=$(/usr/bin/my_print_defaults mysqld|grep server-id |tail -n 1|awk -F= '{print $2}')
    actual_server_id=$(/usr/bin/mysql -e "show global variables like 'server_id'"|grep "server_id"|awk '{print $2}')

    if [[ ! -z "${config_server_id}" ]] && [[ "${config_server_id}" != "${actual_server_id}" ]]; then
      mysql -e "set global server_id=${config_server_id}"
    fi
  EOH
  action :nothing
end

bash "create mysql user and directories" do
  code <<-EOH
# creating mysql group if he isn't already there
if ! getent group mysql >/dev/null; then
        # Adding system group: mysql.
        addgroup --system mysql >/dev/null
fi

# creating mysql user if he isn't already there
if ! getent passwd mysql >/dev/null; then
        # Adding system user: mysql.
        adduser \
          --system \
          --disabled-login \
          --ingroup mysql \
          --no-create-home \
          --home /nonexistent \
          --gecos "MySQL Server" \
          --shell /bin/false \
          mysql  >/dev/null
fi

mkdir -p /etc/mysql
cp /root/my.cnf /etc/mysql # on chef, use template to upload my.cnf
chown -R mysql:mysql /etc/mysql/
mkdir -p #{node['mysql']['datadir']}
mkdir -p #{node['mysql']['ssldir']}
mkdir -p #{node['mysql']['logbase']}
touch #{node['mysql']['logbase']}/mysqld.err
chown -R mysql:mysql /db/mysql
EOH
end

handle_mysql_d

managed_template "/etc/mysql/percona-server.cnf" do
  owner "mysql"
  group "mysql"
  mode "644"
  source "my.conf.erb"
  notifies :run, "bash[adjust-mysql-server-id]", :delayed
  variables(lazy do
    {
      datadir: node["mysql"]["datadir"],
      ssldir: node["mysql"]["ssldir"],
      mysql_version: Gem::Version.new(node["mysql"]["short_version"]),
      mysql_5_7: Gem::Version.new("5.7"),
      mysql_full_version: `[ -f "/db/.lock_db_version" ] && grep -E -o '^[0-9]+\.[0-9]+\.[0-9]+' /db/.lock_db_version || echo #{node["mysql"]["latest_version"]} `.chomp,
      logbase: node["mysql"]["logbase"],
      innodb_buff: innodb_buff,
      replication_master: node["dna"]["instance_role"] == "db_master",
      replication_slave: node["dna"]["instance_role"] == "db_slave",
      server_id: server_id,
    }
  end)
end

bash "Set my.cnf alternatives" do
  code <<-EOS
  update-alternatives --install /etc/mysql/my.cnf my.cnf /etc/mysql/percona-server.cnf 1000
  update-alternatives --set my.cnf /etc/mysql/percona-server.cnf
  EOS
end

logrotate "mysql_slow" do
  files "#{node['mysql']['logbase']}/slow_query.log"
  delay_compress true
  copy_then_truncate true
end

directory "/etc/mysql.d" do
  owner "mysql"
  group "mysql"
  mode "755"
end

directory "/mnt/mysql/tmp" do
  owner "mysql"
  group "mysql"
  mode "755"
  recursive true
end

directory "/var/run/mysqld" do
  owner "mysql"
  group "mysql"
  mode "755"
end

ey_cloud_report "mysql config" do
  message "mysql config and dir creation finished"
end
