ey_cloud_report "puma" do
  message "processing puma"
end

base_port     = 8000
stepping      = 200
app_base_port = base_port
ports = []

# Total workers are based on CPU counts on target instance, with a minimum of 1 worker per app
workers = [(1.0 * get_pool_size() / node["dna"]["applications"].size).round, 1].max
# Adding puma restart sleep timeout
sleep_timeout = "4"

node.engineyard.apps.each_with_index do |app, index|
  app_base_port = base_port + (stepping * index)
  app_path      = "/data/#{app.name}"
  deploy_file   = "#{app_path}/current/REVISION"
  log_file      = "#{app_path}/shared/log/puma.log"
  ssh_username  = node.engineyard.environment.ssh_username
  framework_env = node["dna"]["environment"]["framework_env"]

  ports = (app_base_port...(app_base_port + workers)).to_a

  directory "#{app.name} nginx app directory for puma" do
    path "/data/nginx/servers/#{app.name}"
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "0775"
  end

  file "#{app.name} custom.conf for puma" do
    path "/data/nginx/servers/#{app.name}/custom.conf"
    action :create_if_missing
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "0644"
  end

  directory "/var/run/engineyard/#{app.name}" do
    owner ssh_username
    group ssh_username
    mode "0755"
    recursive true
  end

  template "/data/#{app.name}/shared/config/env" do
    source "env.erb"
    backup 0
    owner ssh_username
    group ssh_username
    mode "0755"
    variables(app_name: app.name,
              user: ssh_username,
              deploy_file: deploy_file,
              framework_env: framework_env,
              baseport: app_base_port,
              workers: workers,
              threads: ""
             )
  end

  template "/engineyard/bin/app_#{app.name}" do
    source  "app_control.erb"
    owner   ssh_username
    group   ssh_username
    mode    "0755"
    backup  0
    variables(app_name: app.name,
              app_dir: "#{app_path}/current",
              deploy_file: deploy_file,
              shared_path: "#{app_path}/shared",
              ports: ports,
              framework_env: framework_env,
              sleep_timeout: sleep_timeout)
  end

  logrotate "puma_#{app.name}" do
    files log_file
    copy_then_truncate
  end

  managed_template "/etc/monit.d/puma_#{app.name}.monitrc" do
    source "puma.monitrc.erb"
    owner "root"
    group "root"
    mode "0666"
    backup 0
    variables(app: app.name,
              app_memory_limit: app_server_get_worker_memory_size(app),
              username: ssh_username,
              ports: ports)
    notifies :run, "execute[reload-monit]"
  end
end
