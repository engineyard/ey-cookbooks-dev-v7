default["elasticache-redis"].tap do |elasticache|

  elasticache['ey_elastic_redis_enabled'] = fetch_env_var(node, "EY_ELASTICACHE_REDIS_ENABLED")
  elasticache['ey_elastic_redis_url']     = fetch_env_var(node, "EY_ELASTICACHE_REDIS_URL")
  elasticache['ey_redis']                 = fetch_env_var(node, "EY_REDIS")

end
