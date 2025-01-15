lock_major_version = `[ -f "/db/.lock_db_version" ] && grep -E -o '^[0-9]+\.[0-9]+' /db/.lock_db_version `
db_stack = lock_major_version == "" ? attribute["dna"]["engineyard"]["environment"]["db_stack_name"] : "mysql#{lock_major_version.gsub(/\./, '_').strip}"

default["latest_version_57"] = `apt-cache madison percona-server-common-5.7 | sort -V | awk '{print $3'} | tail -1`.split("-")[0]
default["latest_version_80"] = `apt-cache madison percona-server-common | sort -V | awk '{print $3'} | tail -1`.split("-")[0]

major_version = ""
custom_version = fetch_env_var(node, "EY_MYSQL_VERSION", nil)

case db_stack
when "mysql5_7", "aurora5_7", "mariadb10_1"
  major_version = "5.7"
  default["mysql"]["latest_version"] = node["latest_version_57"]

when "mysql8_0", "aurora8_0"
  major_version = "8.0"
  default["mysql"]["latest_version"] = node["latest_version_80"]
end

if custom_version
  major_version = custom_version.match(/\d../)[0]
  default["mysql"]["latest_version"] = custom_version
end

default["mysql"]["short_version"] = major_version
default["mysql"]["logbase"] = "/db/mysql/#{major_version}/log/"
default["mysql"]["datadir"] = "/db/mysql/#{major_version}/data/"
default["mysql"]["ssldir"] = "/db/mysql/#{major_version}/ssl/"
default["mysql"]["dbroot"] = "/db/mysql/"
default["mysql"]["owner"] = "mysql"
