include_recipe "ey-deploy-keys"

# TODO: Remove this chunk to the db_master recipe
is_solo = ["solo"].include?(node["dna"]["instance_role"])
unless is_solo # for solo leave the db stuff to the db cookbook
  case node.engineyard.environment["db_stack_name"]
  when /^postgres\d+/, /^aurora-postgresql\d+/
    # include_recipe "postgresql::default"
  when /^mysql\d+/, /^aurora\d+/, /^mariadb\d+/
    # include_recipe "mysql::client"
    # include_recipe "mysql::user_my.cnf"
  when "no_db"
    # no-op
  end
end

include_recipe "ey-app::remove"
include_recipe "ey-app-logs"
include_recipe "ey-app::create"
include_recipe "ey-db-libs"
include_recipe "ey-haproxy"
