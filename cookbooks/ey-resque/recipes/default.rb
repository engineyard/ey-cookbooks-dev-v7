#
# Cookbook:: ey-resque
# Recipe:: default
#
if node["resque"]["is_resque_instance"]

  # bin script
  cookbook_file "/engineyard/bin/resque" do
    mode "0755"
    source "resque"
  end

  node["resque"]["applications"].each do |app_name|
    template "/etc/monit.d/resque_#{app_name}.monitrc" do
      owner "root"
      group "root"
      mode "0644"
      source "monitrc.conf.erb"
      variables(
      num_workers: node["resque"]["worker_count"],
      app_name: app_name,
      rails_env: node["dna"]["environment"]["framework_env"]
    )
    end

    node["resque"]["worker_count"].times do |count|
      template "/data/#{app_name}/shared/config/resque_#{count}.conf" do
        owner node["owner_name"]
        group node["owner_name"]
        mode "0644"
        source "resque_wildcard.conf.erb"
      end
    end

    execute "ensure-resque-is-setup-with-monit" do
      ignore_failure true
      command "monit reload"
    end
  end
end
