#
# Cookbook:: ey-memcached
# Attributes:: default
#
default["memcached"].tap do |memcached|
  # Default: DO NOT install memcached
  # Override this to true to install memcached
  memcached["perform_install"] = false

  # Set to true if you want to install from source
  # but not all versions are available
  memcached["install_from_source"] = false

  # If install_from_source is enabled.
  # Otherwise the default Ubuntu 20.04 memcached package will be installed.
  memcached["version"] = "1.5.22-2"
  memcached["download_url"] = "http://www.memcached.org/files/memcached-#{memcached['version']}.tar.gz"

  # Install memcached on a utility instance named "memcached"
  # memcached["install_type"] = "NAMED_UTILS"
  memcached["utility_name"] = "memcached"
  memcached["install_type"] = "NAMED_UTILS"

  # Install memcached on all app instances, or on a solo instance
  # memcached["install_type"] = "ALL_APP_INSTANCES"

  # Amount of memory in MB to be used by memcached
  memcached["memusage"] = 1024

  # Additional memcached configuration options
  # Default: no additional options
  memcached["misc_opts"] = ""

  # Try increasing the growth factor if you allocated more memory to memcached
  # and you're seeing lots of partially-filled slabs
  # memcached["misc_opts"] = "-f 1.5"
  # See https://blog.engineyard.com/2015/fine-tuning-memcached
end
