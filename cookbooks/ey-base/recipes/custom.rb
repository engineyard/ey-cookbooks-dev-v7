if fetch_env_var(node, "EY_REDIS_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-redis"
end

if fetch_env_var(node, "EY_MEMCACHED_ENABLED") =~ /^TRUE$/i
  include_recipe "memcached"
end

if fetch_env_var(node, "EY_SIDEKIQ_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-sidekiq"
end

if fetch_env_var(node, "EY_LETSENCRYPT_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-letsencrypt"
end
