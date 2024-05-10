default["elasticache-memcache"].tap do |elasticache|

  elasticache['ey_elastic_memcache_enabled'] = fetch_env_var(node, "EY_ELASTICACHE_MEMCACHE_ENABLED")
  elasticache['ey_elastic_memcache_url']     = fetch_env_var(node, "EY_ELASTICACHE_MEMCACHE_URL")
  elasticache['ey_memcache']                 = fetch_env_var(node, "EY_MEMCACHE")

end
