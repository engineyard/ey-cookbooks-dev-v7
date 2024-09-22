# ey-logentries

**Logentries is now known as Rapid7 insightops. For using this cookbook, you would need access to logentries dashboard(_not_ InsightOps)

This recipe is used to run Logentries on the stable-v7 stack.

We accept contributions for changes that can be used by all customers.

## Configuration

Logentries can be set up by configuring the following environment variables:

1. `EY_LOGENTRIES_API_KEY`: Required. Set this to your Logentries API key.

2. `EY_LOGENTRIES_FOLLOW_PATHS`: Optional. Use this to specify custom log paths for all instance types. The value should be a JSON-formatted string. For example:
   ```
   EY_LOGENTRIES_FOLLOW_PATHS -> {"path":"/custom/log/path.log"}{"path":"/another/custom/log.log"}
   ```

3. Role-specific log paths: Optional. You can specify custom log paths for specific instance roles using the following environment variables:
   - `EY_LOGENTRIES_FOLLOW_PATHS_APP`: For application instances
   - `EY_LOGENTRIES_FOLLOW_PATHS_UTIL`: For utility instances
   - `EY_LOGENTRIES_FOLLOW_PATHS_DB`: For database instances
   - `EY_LOGENTRIES_FOLLOW_PATHS_SOLO`: For solo instances

   Each of these variables should be set with a JSON-formatted string. For example:
   ```
   EY_LOGENTRIES_FOLLOW_PATHS_APP -> {"path":"/data/app_name/current/log/production.log"}
   EY_LOGENTRIES_FOLLOW_PATHS_UTIL -> {"path":"/data/app_name/current/log/background_jobs.log"}
   ```

## Default Behavior

- By default, Logentries will follow these system logs on all instances:
  - `/var/log/syslog`
  - `/var/log/auth.log`
  - `/var/log/daemon.log`

- For application and application master instances (`app` and `app_master` roles), Logentries will also follow the Nginx access logs for each application:
  - `/var/log/nginx/[app_name].access.log`

## Customization

You can customize the logs that Logentries follows by using the environment variables mentioned above. This allows you to add application-specific logs or any other custom logs you want to monitor.