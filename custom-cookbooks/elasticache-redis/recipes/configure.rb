#
# Cookbook Name:: redis
# Recipe:: configure
#

if node['elasticache-redis']['ey_elastic_redis_enabled']

  if node["elasticache-redis"]['ey_redis']
    # ERROR both EY_REDIS and ELASTICACHE Enabled
  end

  if node['elasticache-redis']['ey_elastic_redis_url'].nil? || node['elasticache-redis']['ey_elastic_redis_url'].empty?
    # ERROR URL missing
  end

  if ['solo', 'app', 'app_master', 'util'].include?(node['dna']['instance_role'])

    node['dna']['applications'].each do |app, data|
      template "/data/#{app}/shared/config/redis.yml"do
        source 'redis.yml.erb'
        owner node['owner_name']
        group node['owner_name']
        mode 0655
        backup 0
        variables({
          'hostname' => node['elasticache-redis']['ey_elastic_redis_url'],
          'environment' => node["dna"]["engineyard"]["environment"]["framework_env"]
        })
      end
    end

  end

end
