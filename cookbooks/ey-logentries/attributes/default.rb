default["logentries"]["le_api_key"] = fetch_env_var(node, "EY_LOGENTRIES_API_KEY", "YOUR_API_KEY_HERE")

# Default follow paths
default["logentries"]["follow_paths"] = fetch_env_var(node, "EY_LOGENTRIES_FOLLOW_PATHS", "{}").split(/(?<=[}])/)

# Role-specific follow paths
%w[app util db solo].each do |role|
  env_var_name = "EY_LOGENTRIES_FOLLOW_PATHS_#{role.upcase}"
  default["logentries"]["follow_paths_#{role}"] = fetch_env_var(node, env_var_name, "{}").split(/(?<=[}])/)
end