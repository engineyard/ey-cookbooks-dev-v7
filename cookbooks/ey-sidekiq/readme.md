# EY-Sidekiq 

This recipe is used to run Sidekiq on the stable-v7 stack.

The sidekiq recipe is managed by Engine Yard.
This recipe is one of the default recipes in v7 stack. You can enable it by using environment variables.
You can modify the recipe for your own needs using a custom-sidekiq recipe.

For sidekiq to run properly you also need [redis](https://github.com/engineyard/ey-cookbooks-stable-v7/tree/next-release/cookbooks/ey-redis). If your redis is in a dedicated utility instance, you have to make some adjustments to your application so that sidekiq can find the redis instance. You need to create a `sidekiq.rb` file in `config/initializers` folder of your rails application.

```ruby
redis_config = YAML.load_file(Rails.root + 'config/redis.yml')[Rails.env]

Sidekiq.configure_server do |config|
  config.redis = {
    url: "redis://#{redis_config['host']}:#{redis_config['port']}"
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "redis://#{redis_config['host']}:#{redis_config['port']}"
  }
end
```

We accept contributions for changes that can be used by all customers.

## Environment Variables

| Environment Variable                     | Default Value  | Description                                                     |
| ---------------------------------------- | -------------- | --------------------------------------------------------------- |
| `EY_SIDEKIQ_ENABLED`                     | `false`        | Enables Sidekiq                                                 |
| `EY_SIDEKIQ_INSTANCES_ROLE`              | N/A            | Pattern to match for instance roles.*                           |
| `EY_SIDEKIQ_INSTANCES_NAME`              | N/A            | Pattern to match for instance names.*                           |
| `EY_SIDEKIQ_NUM_WORKERS`                 | 1              | The number of Sidekiq workers per instance.                     |
| `EY_SIDEKIQ_CONCURRENCY`                 | 25             | The number of threads in each worker.                           |
| `EY_SIDEKIQ_WORKER_MEMORY_MB`            | 400            | Maximum worker memory in MB.                                    |
| `EY_SIDEKIQ_VERBOSE`                     | `false`        | Activate verbose mode.                                          |
| `EY_SIDEKIQ_ORPHAN_MONITORING_ENABLED`   | `false`        | Activate a cronjob which monitors for orphan sidekiq processes. |
| `EY_SIDEKIQ_ORPHAN_MONITORING_SCHEDULE`  | `*/5 * * * *`  | Cron schedule for the orphan monitor.                           |
| `EY_SIDEKIQ_QUEUE_PRIORITY_<queue_name>` | `default => 1` | Set additional queue priorities.**                              |
| `EY_SIDEKIQ_MAX_RETRIES`                 | 0              | Set max retries.                         |

*: These environment variables match instances by their role and name.
   Every matching instance is set up to run sidekiq workers.
   The values are regular expressions.
   The two matches are combined via a logical `and`.
   Any variable that's not set, matches all instances by default.
   So, if you want to install sidekiq on all instances, don't set any of those variables.

**: The name of this environment variable is dynamic and contains 
    the name of the queue (`<queue_name>`) at the end.
    The value is the numeric priority for that queue.

### Restart after Deployments

If Sidekiq is configured via environment variables, as documented above,
a hook is automatically created which restarts the Sidekiq workers automatically
after each deployment.