### ************************************* IMPORTANT NOTE ********************************************
## Under v5 and higher we now rely on a combined run where custom recipes are directly overlayed on
## the existing cookbooks. This effectively removes the need for `keep` file use. This functionality
## is being maintained for compatibility reasons for now and may become deprecated in the future.
### *************************************************************************************************

class Chef
  class Resource
    class ManagedTemplate < Template
      provides :managed_template
      def initialize(name, run_context = nil)
        super(name, run_context)
        not_if { ::File.exist?(name.sub(/(.*)(\/)/, "\\1\/keep.")) }
      end
    end
  end
end

Chef::Provider::Template.provides :managed_template

# This is just a small wrapper around template that allows us to add a not_if condition as follows:
# take the full path of the template "/data/someservice.conf" and check for a file on the filesystem
# called "/data/keep.someservice.conf"

# so for this managed_template resource
# managed_template "/data/someservice.conf" do
#   owner "ez"
#   mode 0755
#   source "someservice.conf.erb"
#   action :create
#   variables :applications => ["foo", "bar", "baz"]
# end
#
# a not_if condition as follows gets automatically added for you:
# not_if { ::File.exist?("/data/keep.someservice.conf") }
#
# This allows for a user of a managed system to say "Hey I've made changes to this
# config file, DO NOT CLOBBER IT! KTHXBYE" by just prepending any file they want to manage by hand with 'keep.'

def create_managed_template(path)
  ChefSpec::Matchers::ResourceMatcher.new(:managed_template, :create, path)
end
