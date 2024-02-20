unattended_flag_string = fetch_env_var(node, "EY_ENABLE_UNATTENDED_UPGRADES", "false")
unattended_flag = unattended_flag_string.downcase == "true" || unattended_flag_string == "1" ? 1 : 0

template "/etc/apt/apt.conf.d/20auto-upgrades" do
  mode "0644"
  source "auto-upgrades.erb"
  backup false
  variables(
    unattended_flag: unattended_flag
  )
end

cookbook_file "/etc/apt/apt.conf.d/50unattended-upgrades" do
  source "50unattended-upgrades"
  owner "root"
  group "root"
  mode "0644"
end
