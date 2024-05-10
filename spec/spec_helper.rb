require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.log_level = :fatal
  config.platform = 'ubuntu'
  config.version = '20.04'
end