execute "le register --account-key" do
  command "/usr/bin/le register --account-key #{node['logentries']['le_api_key']} --name #{node['dna']['applications'].keys.first}/#{node['dna']['engineyard']['this']}"
  action :run
  not_if { ::File.exist?("/etc/le/config") }
end

follow_paths = []
# Add custom follow paths from general environment variable
node["logentries"]["follow_paths"].each do |path|
  path = JSON.parse(path)
  if path.is_a?(Hash) && path["path"]
    follow_paths << path["path"]
  end
end

# Add role-specific follow paths
instance_role = node["dna"]["instance_role"]
role_specific_paths = node["logentries"]["follow_paths_#{instance_role}"]
role_specific_paths.each do |path|
  path = JSON.parse(path)
  if path.is_a?(Hash) && path["path"]
    follow_paths << path["path"]
  end
end

follow_paths.uniq.each do |path|
  execute "le follow #{path}" do
    command "le follow #{path}"
    ignore_failure true
    action :run
    not_if "le followed #{path}"
  end
end
