#
# Cookbook Name:: memcache
# Recipe:: configure
#

if node['elasticache-memcache']['ey_elastic_memcache_enabled']

  if node['elasticache-memcache']['ey_memcache']
    # ERROR both EY_MEMCACHE and ELASTICACHE Enabled
  end

  if node['elasticache-memcache']['ey_elastic_memcache_url'].nil? || node['elasticache-memcache']['ey_elastic_memcache_url'].empty?
    # ERROR URL missing
  end

  if ['solo', 'app', 'app_master', 'util'].include?(node['dna']['instance_role'])

    node['dna']['applications'].each do |app, data|
      template "/data/#{app}/shared/config/memcached.yml"do
        source 'memcached.yml.erb'
        owner node['owner_name']
        group node['owner_name']
        mode 0655
        backup 0
        variables({
          'hostname' => node['elasticache-memcache']['ey_elastic_memcache_url'],
          'environment' => node["dna"]["engineyard"]["environment"]["framework_env"]
        })
      end
    end

  end

end
