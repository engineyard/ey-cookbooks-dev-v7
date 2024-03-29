ey_cloud_report "mysql installation" do
  message "Installation of MySQL packages and dependencies started."
end

apt_repository "mysql57" do
  uri "http://repo.percona.com/ps-57/apt"
  distribution "#{`lsb_release -cs`.strip}"
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "9334A25F8507EFA5"
end.run_action(:add)

apt_repository "mysql80" do
  uri "http://repo.percona.com/ps-80/apt"
  distribution "#{`lsb_release -cs`.strip}"
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "9334A25F8507EFA5"
end.run_action(:add)

known_versions = []
install_version = node["mysql"]["latest_version"]
short_version = node["mysql"]["short_version"]

`apt-cache madison percona-server-server-#{short_version} | awk '{print $3}' && apt-cache madison percona-server-server | awk '{print $3}'`.split(/\n+/).each do |v|
  known_versions.append(v.split("-")[0])
end
package_version = known_versions.detect { |v| v =~ /^#{install_version}/ }

if node.engineyard.environment.lock_db_version?
  lock_db_version = node.engineyard.environment.components.find_all { |e| e["key"] == "lock_db_version" }.first["value"]
end

lock_version_file = "/db/.lock_db_version"
db_running = `mysql -N -e "select 1;" 2> /dev/null`.strip == "1"

# Create or delete /db/.lock_db_version
if node["dna"]["instance_role"][/^(db|solo)/]
  execute "dropping lock version file" do
    command "echo $(mysql --version | grep -E -o '(Distrib|Ver) [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $NF}') > #{lock_version_file}"
    action :run
    only_if { lock_db_version && !::File.exist?(lock_version_file) && db_running }
  end

  execute "remove lock version file" do
    command "rm #{lock_version_file}"
    only_if { !lock_db_version && ::File.exist?(lock_version_file) }
  end
end

# Install the dependencies of the Percona packages
["debsums", "libaio1", "libmecab2"].each do |package|
  package package do
    action :install
  end
end

package "libmysqlclient-dev" do
  action :install
end

# Installs MySQL client to all instances
if node.engineyard.instance.arch_type == "arm64"
  package "mysql-client" do
    action :install
  end
else
  case short_version
  when "5.7"
    package "percona-server-client-5.7" do
      action :install
    end
  when "8.0"
    package "percona-server-client" do
      action :install
    end
  end
end

packages = case short_version
           when "5.7"
             ["percona-server-common-5.7", "libperconaserverclient20", "percona-server-server-5.7"]
           when "8.0"
             ["percona-server-common", "libperconaserverclient21", "percona-server-server"]
           end

if node["dna"]["instance_role"][/db|solo/]
  directory "/etc/systemd/system/mysql.service.d" do
    owner "root"
    group "root"
    mode "755"
    recursive true
  end

  cookbook_file "/etc/systemd/system/mysql.service.d/override.conf" do
    source "mysql_override.conf"
    owner "root"
    group "root"
    mode "644"
    notifies :run, "execute[reload-systemd]", :immediately
  end
end

install_version = if ::File.exist?(lock_version_file)
                    `cat #{lock_version_file}`.strip
                  else
                    node["mysql"]["latest_version"]
                  end

if package_version.nil? && node.engineyard.instance.arch_type == "amd64"
  raise "Chef does not know about MySQL version #{install_version}. The current known versions of MySQL are #{known_versions.join(', ')}. Please use them or contact support for more assistance."
end

package_version = `apt-cache madison #{packages.last} | awk '{print $3}' | grep #{install_version}`.split(/\n/).last

execute "set-deb-confs" do
  command %(echo "#{packages.last} #{packages.last}/root-pass password #{node.engineyard.environment['db_admin_password']}" | debconf-set-selections && echo "#{packages.last} #{packages.last}/re-root-pass password #{node.engineyard.environment['db_admin_password']}" | debconf-set-selections)
end

# Loop through the packages because chef doesn't understand you install the dependency before even in the array...
if node["dna"]["instance_role"][/^(db|solo)/]
  packages.each do |package|
    apt_package package do
      version package_version
      action :install
      options "--yes --fix-missing"
      ignore_failure true
      only_if { node.engineyard.instance.arch_type == "amd64" }
    end
  end
end

ey_cloud_report "mysql installation" do
  message "Installation of MySQL packages and dependencies finished."
end

if node["dna"]["instance_role"][/^(db|solo)/] && short_version == "8.0"
  bash "Set my.cnf alternatives for MySQL 8.0" do
    code <<-EOS
      update-alternatives --install /etc/mysql/my.cnf my.cnf /etc/mysql/percona-server.cnf 1000
      update-alternatives --set my.cnf /etc/mysql/percona-server.cnf
    EOS
  end
end
