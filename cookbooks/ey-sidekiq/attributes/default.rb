default["sidekiq"].tap do |sidekiq|
  is_sidekiq_enabled = !!(fetch_env_var(node, "EY_SIDEKIQ_ENABLED", "false") =~ /^TRUE$/i)

  # By default we install sidekiq on all utility instances
  # If there are no utility instances available sidekiq is not installed
  # We use regex so it could be installed on all app instances using app for example

  does_role_match = Regexp.new(fetch_env_var(node, "EY_SIDEKIQ_INSTANCES_ROLE", "util")).match(node["dna"]["instance_role"]) ? true : false
  does_name_match = Regexp.new(fetch_env_var(node, "EY_SIDEKIQ_INSTANCES_NAME", "")).match(node["dna"]["name"].to_s) ? true : false
  not_database = !(node["dna"]["instance_role"] =~ /^db_/)

  sidekiq["is_sidekiq_instance"] = (is_sidekiq_enabled && does_role_match && does_name_match && not_database)

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
  sidekiq["worker_threshold_memory"] = fetch_env_var(node, "EY_SIDEKIQ_WORKER_THRESHOLD_MEMORY_MB", sidekiq["worker_memory"]*8/10).to_i # MB

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
