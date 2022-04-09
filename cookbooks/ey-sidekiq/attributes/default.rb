default["sidekiq"].tap do |sidekiq|
  is_sidekiq_enabled = (fetch_env_var(node, "EY_SIDEKIQ_ENABLED", "false") =~ /^TRUE$/i)
  # Sidekiq will be installed on to application/solo instances,
  # unless a utility name is set, in which case, Sidekiq will
  # only be installed on to a utility instance that matches
  # the name
  #role_pattern = fetch_env_var(node, "EY_SIDEKIQ_INSTANCES_ROLE", "util")
  does_role_match = Regexp.new(fetch_env_var(node, "EY_SIDEKIQ_INSTANCES_ROLE", "util")).match(node["dna"]["instance_role"]) ? true : false

  #name_pattern = fetch_env_var(node, "EY_SIDEKIQ_INSTANCES_NAME", "sidekiq")
  does_name_match = Regexp.new(fetch_env_var(node, "EY_SIDEKIQ_INSTANCES_NAME", "sidekiq")).match(node["dna"]["name"]) ? true : false

  sidekiq["is_sidekiq_instance"] = (is_sidekiq_enabled && does_role_match && does_name_match && !node["dna"]["instance_role"] =~ /^db_/)

  # We create an on-instance `after_restart` hook only
  # when the recipe was enabled via environment variables.
  # Otherwise the behaviour for custom-cookbooks would change
  # which is undesirable.
  sidekiq["create_restart_hook"] = is_sidekiq_enabled

  # Number of workers (not threads)
  sidekiq["workers"] = fetch_env_var(node, "EY_SIDEKIQ_NUM_WORKERS", 1).to_i

  # Concurrency
  sidekiq["concurrency"] = fetch_env_var(node, "EY_SIDEKIQ_CONCURRENCY", 25).to_i

  # Queues
  sidekiq["queues"] = {
    # :queue_name => priority
    default: 1,
  }
  fetch_env_var_patterns(node, /^EY_SIDEKIQ_QUEUE_PRIORITY_([a-zA-Z0-9_]+)$/).each do |queue_var|
    queue_name = queue_var[:match][1].to_sym
    queue_priority = queue_var[:value].to_i
    sidekiq["queues"][queue_name] = queue_priority
  end

  # Memory limit
  sidekiq["worker_memory"] = fetch_env_var(node, "EY_SIDEKIQ_WORKER_MEMORY_MB", 400).to_i # MB

  # Verbose
  sidekiq["verbose"] = fetch_env_var(node, "EY_SIDEKIQ_VERBOSE", false).to_s == "true"

  # Setting this to true installs a cron job that
  # regularly terminates sidekiq workers that aren't being monitored by monit,
  # and terminates those workers
  #
  # default: false
  sidekiq["orphan_monitor_enabled"] = fetch_env_var(node, "EY_SIDEKIQ_ORPHAN_MONITORING_ENABLED", false).to_s == "true"

  # sidekiq_orphan_monitor cron schedule
  #
  # default: every 5 minutes
  sidekiq["orphan_monitor_cron_schedule"] = fetch_env_var(node, "EY_SIDEKIQ_ORPHAN_MONITORING_SCHEDULE", "*/5 * * * *")
end
