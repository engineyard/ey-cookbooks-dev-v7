postgres_root    = "/db/postgresql"
postgres_temp    = "/mnt/postgresql/tmp"
postgres_version = node["postgresql"]["short_version"]

sysctl "kernel.sem" do
  value "250 32000 32 512"
end

sysctl "vm.swappiness" do
  value 15
end

service "postgresql used for notifications" do
  service_name "postgresql"
  supports restart: true, reload: true, status: true
  action :nothing
end

directory "/var/run/postgresql" do
  owner "postgres"
  group "postgres"
  mode "0755"
  action :create
  recursive true
end

# the newer pg init scripts actually force 0770 perms on /var/run/postgres
# this will ensure the deploy user can still use localhost connections
group "postgres" do
  action :modify
  append true
  members node.engineyard.environment.ssh_username
end

directory postgres_temp do
  owner "postgres"
  group "postgres"
  mode "0755"
  action :create
  recursive true
end

zone = "#{node.engineyard.environment['timezone']}"
zonepath = "/usr/share/zoneinfo/#{zone}"
timezone = (File.exist?(zonepath) && !zone.empty?) ? zone : "GMT"

if ["app_master", "solo", "db_master"].include?(node["dna"]["instance_role"])
  ey_cloud_report "configuring postgresql #{postgres_version}" do
    message "processing postgresql #{postgres_version} configuration"
  end

  directory "#{postgres_root}/#{postgres_version}" do
    owner "postgres"
    group "postgres"
    mode "0755"
    action :create
    recursive true
  end

  initdb_path = "/usr/lib/postgresql/#{postgres_version}/bin/initdb"
  execute "init-postgres" do
    command "echo #{node.engineyard.environment['db_admin_password']} > /tmp/.pass && #{initdb_path} -D #{postgres_root}/#{postgres_version}/data --encoding=UTF8 --locale=en_US.UTF-8 --pwfile=/tmp/.pass; rm /tmp/.pass > /dev/null 2>&1"
    action :run
    user "postgres"
    not_if { FileTest.directory?("#{postgres_root}/#{postgres_version}/data") }
  end

  template "#{postgres_root}/#{postgres_version}/data/postgresql.conf" do
    source "postgresql.conf.erb"
    owner "postgres"
    group "root"
    mode "600"
    backup 0
    notifies :reload, "service[postgresql]"
    variables(
      pg_port: "5432",
      data_directory: "/db/postgresql/#{postgres_version}/data",
      ssl_directory: node["postgresql"]["ssldir"],
      wal_level: postgres_version_gte?("9.6") ? "replica" : "hot_standby",
      shared_buffers: node["shared_buffers"],
      maintenance_work_mem: node["maintenance_work_mem"],
      work_mem: node["work_mem"],
      max_stack_depth: "6MB", # not large enough for 8? updating limits would do it but that's the AMI and we shouldn't use ulimit -s to work around it.
      effective_cache_size: node["effective_cache_size"],
      default_statistics_target: node["default_statistics_target"],
      logging_collector: node["logging_collector"],
      log_rotation_age: node["log_rotation_age"],
      log_rotation_size: node["log_rotation_size"],
      checkpoint_timeout: node["checkpoint_timeout"],
      checkpoint_segments: node["checkpoint_segments"],
      wal_buffers: node["wal_buffers"],
      wal_writer_delay: node["wal_writer_delay"],
      postgres_root: postgres_root,
      postgres_version: postgres_version,
      hot_standby: "on",
      archive_timeout: "0",
      timezone: timezone
    )
    helpers(PostgreSQL::Helper)
  end
end

if ["db_slave"].include?(node["dna"]["instance_role"])

  ey_cloud_report "postgresql slave" do
    message "processing postgresql #{postgres_version} configuration"
  end

  # used for enabling WAL archiving
  directory "#{postgres_root}/#{postgres_version}/wal" do
    owner "postgres"
    group "postgres"
    mode "0755"
    action :create
    recursive true
  end

  if File.exist?("#{postgres_root}/#{postgres_version}/data/postmaster.pid")
    # TODO: Improve this check to see if the slave is up and running.
  else
    postgresql_slave node["dna"]["db_host"] do
      require "yaml"
      password node.engineyard.environment["db_admin_password"]
    end
  end

  if postgres_version_gte?("12")
    template "#{postgres_root}/#{postgres_version}/data/postgresql.conf" do
      source "postgresql12.conf.erb"
      owner "postgres"
      group "root"
      mode "600"
      backup 0
      notifies :reload, "service[postgresql]"
      variables(
        pg_port: "5432",
        data_directory: "/db/postgresql/#{postgres_version}/data",
        ssl_directory: node["postgresql"]["ssldir"],
        wal_level: "hot_standby",
        shared_buffers: node["shared_buffers"],
        maintenance_work_mem: node["maintenance_work_mem"],
        work_mem: node["work_mem"],
        max_stack_depth: "6MB", # not large enough for 8? updating limits would do it but that's the AMI and we shouldn't use ulimit -s to work around it.
        effective_cache_size: node["effective_cache_size"],
        default_statistics_target: node["default_statistics_target"],
        logging_collector: node["logging_collector"],
        log_rotation_age: node["log_rotation_age"],
        log_rotation_size: node["log_rotation_size"],
        checkpoint_timeout: node["checkpoint_timeout"],
        checkpoint_segments: node["checkpoint_segments"],
        wal_buffers: node["wal_buffers"],
        wal_writer_delay: node["wal_writer_delay"],
        postgres_root: postgres_root,
        postgres_version: postgres_version,
        hot_standby: "on",
        archive_timeout: "0",
        timezone: timezone,
        primary_host: node["dna"]["db_host"],
        primary_user: "postgres",
        primary_password: node.engineyard.environment["db_admin_password"],
        promote_trigger_file: "/tmp/postgresql.trigger",
        conn_app_name: node.name || node.instance.id
      )
      helpers(PostgreSQL::Helper)
    end

    execute "touch standby.signal" do
      command "touch #{postgres_root}/#{postgres_version}/data/standby.signal"
    end
  else
    template "#{postgres_root}/#{postgres_version}/data/postgresql.conf" do
      source "postgresql.conf.erb"
      owner "postgres"
      group "root"
      mode "600"
      backup 0
      notifies :reload, "service[postgresql]"
      variables(
        pg_port: "5432",
        data_directory: "/db/postgresql/#{postgres_version}/data",
        ssl_directory: node["postgresql"]["ssldir"],
        wal_level: "hot_standby",
        shared_buffers: node["shared_buffers"],
        maintenance_work_mem: node["maintenance_work_mem"],
        work_mem: node["work_mem"],
        max_stack_depth: "6MB", # not large enough for 8? updating limits would do it but that's the AMI and we shouldn't use ulimit -s to work around it.
        effective_cache_size: node["effective_cache_size"],
        default_statistics_target: node["default_statistics_target"],
        logging_collector: node["logging_collector"],
        log_rotation_age: node["log_rotation_age"],
        log_rotation_size: node["log_rotation_size"],
        checkpoint_timeout: node["checkpoint_timeout"],
        checkpoint_segments: node["checkpoint_segments"],
        wal_buffers: node["wal_buffers"],
        wal_writer_delay: node["wal_writer_delay"],
        postgres_root: postgres_root,
        postgres_version: postgres_version,
        hot_standby: "on",
        archive_timeout: "0",
        timezone: timezone
      )
      helpers(PostgreSQL::Helper)
    end

    template "#{postgres_root}/#{postgres_version}/data/recovery.conf" do
      source "recovery.conf.erb"
      owner "postgres"
      group "root"
      mode "600"
      backup 0
      variables(
        standby_mode: "on",
        primary_host: node["dna"]["db_host"],
        primary_port: 5432,
        primary_user: "postgres",
        primary_password: node.engineyard.environment["db_admin_password"],
        trigger_file: "/tmp/postgresql.trigger",
        postgres_version: postgres_version,
        conn_app_name: node.name || node.instance.id
      )
      helpers(PostgreSQL::Helper)
    end
  end
end

file "#{postgres_root}/#{postgres_version}/custom.conf" do
  action :create
  owner node["owner_name"]
  group node["owner_name"]
  mode "644"
  not_if { FileTest.exists?("#{postgres_root}/#{postgres_version}/custom.conf") }
end

file "#{postgres_root}/#{postgres_version}/custom_pg_hba.conf" do
  action :create
  owner node["owner_name"]
  group node["owner_name"]
  mode "644"
  not_if { FileTest.exists?("#{postgres_root}/#{postgres_version}/custom_pg_hba.conf") }
end

primary_interface = `ip route list | grep default | grep -E  'dev (\w+)' -o | awk '{print $2}'`
ip = `ip address show #{primary_interface} | grep inet | awk '{print $2}' | awk -F: '{print $NF}'`
if ip =~ /^10\./
  cidr = "10.0.0.0/8"
elsif ip =~ /^172\./
  cidr = "172.16.0.0/12"
elsif ip =~ /^192\./
  cidr = "192.168.0.0/16"
end

# Chef versions that don't support the lazy evaluation keyword
# found here: http://blog.arangamani.net/blog/2013/03/24/dynamically-changing-chef-attributes-during-converge/
custom_contents = nil
ruby_block "fill custom_contents" do
  block do
    custom_contents = File.read("#{postgres_root}/#{postgres_version}/custom_pg_hba.conf")

    templ = run_context.resource_collection.find(template: "#{postgres_root}/#{postgres_version}/data/pg_hba.conf")
    templ.variables[:custom_contents] = custom_contents
  end
end

template "#{postgres_root}/#{postgres_version}/data/pg_hba.conf" do
  owner "postgres"
  group "root"
  mode "600"
  source "pg_hba.conf.erb"
  notifies :reload, "service[postgresql]", :immediately
  variables({
    app_users: node.engineyard.apps.collect(&:database_username).uniq,
    cidr: cidr,
    custom_file: "#{postgres_root}/#{postgres_version}/custom_pg_hba.conf",
    custom_contents: custom_contents,
  })
end

include_recipe "ey-db-ssl::setup"

template "/etc/systemd/system/postgresql.service" do
  source "postgresql.service.erb"
  variables({
    version: postgres_version,
    data_directory: node["postgresql"]["datadir"],
    pg_start_timeout: 7200,
    systemd_start_timeout: 7200 + 15,
  })
  notifies :run, "execute[reload-systemd]", :immediately
end

service "postgresql" do
  action [:enable, :start]
  supports restart: true, reload: true, status: true
  timeout 7200
end

cookbook_file "/engineyard/bin/load_postgres_db.sh" do
  source "load_postgres_db.sh"
  backup 0
  mode "744"
end

ruby_block "symlink load_foreign_postgres_db.sh" do
  block do
    ` [ -f /engineyard/bin/load_foreign_postgres_db.sh ] && rm /engineyard/bin/load_foreign_postgres_db.sh `
    ` ln -s /engineyard/bin/load_postgres_db.sh /engineyard/bin/load_foreign_postgres_db.sh `
  end
end

cookbook_file "/engineyard/bin/kill_pg_connections.sh" do
  source "kill_pg_connections.sh"
  backup 0
  mode "744"
end

user "postgres" do
  action :unlock
end

ruby_block "process extensions.json" do
  block do
    # run_context = Chef::RunContext.new(node, {})
    exts = JSON.parse(::File.read(node["pg_extensions_file"]))
    exts.each do |db_name, exts|
      run_context.resource_collection << r = Chef::Resource::PostgresqlPgExtension.new("install #{exts.join(',')} in database #{db_name}", run_context)
      r.db_name = db_name
      r.ext_name = exts
    end
  end
  only_if { ::File.exist?(node["pg_extensions_file"]) }
end

ruby_block "writing initial lock version file" do
  block do
    sleep 1 while running_pg_version.empty?
    File.write(node["lock_version_file"], running_pg_version)
  end
  only_if { lock_db_version and !File.exist?(node["lock_version_file"]) and pg_running }
end
