require_relative "metadata"
require_relative "env_vars"

def pool_size_settings_key_to_env_var(key)
  "EY_#{key.to_s.upcase}"
end

class Engineyard
  module PoolSize
    class Settings
      # default settings
      DEFAULTS = {
        reserved_memory: 1500, # MB
        reserved_memory_solo: 2000, # MB
        worker_memory_size: 250, # MB
        workers_per_ecu: 2,
        min_pool_size: 3,
        max_pool_size: 100,
        db_vcpu_max: 0,
        db_workers_per_ecu: 0.5,
        swap_usage_percent: 25,
      }.freeze

      # setting keys
      KEYS = ["reserved_memory", "reserved_memory_solo", "db_workers_per_ecu", "db_vcpu_max", "worker_memory_size", "workers_per_ecu", "swap_usage_percent", "min_pool_size", "max_pool_size"].map(&:to_sym)

      # attributes
      attr_accessor :recipe

      # new
      def initialize(recipe)
        self.recipe = recipe
      end

      # pool size settings
      def settings
        @settings ||= begin
          settings = build_settings_from_config
          settings[:overridden] = !settings.empty?
          set_defaults(settings)
        end
      end

      def defaults?
        !settings[:overridden]
      end

      def [](key)
        self.settings[key.to_sym]
      end

      protected

      def build_settings_from_config
        KEYS.inject({}) do |memo, key|
          conf_val = self.recipe.metadata_any_get(key)
          conf_val = self.recipe.fetch_env_var(
            self.recipe.node, pool_size_settings_key_to_env_var(key), conf_val)
          conf_val ? memo.merge(key => conf_val) : memo
        end
      end

      def set_defaults(hash)
        KEYS.each do |key|
          hash[key] = case key
          when :reserved_memory
            (self.recipe.node.engineyard.instance.role == "solo" ?
              (hash[:reserved_memory_solo] || DEFAULTS[:reserved_memory_solo]) :
              (hash[:reserved_memory] || DEFAULTS[:reserved_memory])
            ).to_i
          when :workers_per_ecu, :db_workers_per_ecu
            (hash[key] || DEFAULTS[key]).to_f
          else
            (hash[key] || DEFAULTS[key]).to_i
          end
        end

        hash
      end
    end

    class Calculator
      InstanceResource = Struct.new(:vcpus, :defined_ecus, :innodb_pool)
      class InstanceResource
        ECU_TO_VCPU_RATIO = 3.25

        # Amazon has a general conversion ration of 3.25 ECU per VCPU across all but the
        # earliest instance types (as of September 2014). However, their published ECU
        # equivalencies sometimes vary from that. Where the ratio holds true, no specific
        # ECU count needs to be defined, and the resource object will simply calculate
        # the value from the VCPU count using the defined ratio.
        # VCPU and ECU counts were pulled from:
        #   http://aws.amazon.com/ec2/previous-generation/  -- OLD INSTANCE TYPES
        #   http://aws.amazon.com/ec2/pricing/              -- MODERN INSTANCES

        def ecus
          self.defined_ecus || self.vcpus * ECU_TO_VCPU_RATIO
        end
      end

      # If a specific set of values is not defined for the innodb_pool, the
      # recipe to calculate innodb pool size will determine that value algorithmically.
      # If specific values are set, they override the algorithm.

      Resources = Hash.new do |h, k|
        # parse cpuinfo and count the number of cores that it reports; use that as a default if asked for an unknown instance size.
        cores = File.read("/proc/cpuinfo").scan(/processor\s*:.*?cpu\s+cores\s*:\s*(\d+)/m).inject(0) { |a, x| a += x.first.to_i }
        h[k] = InstanceResource.new(cores, nil, nil)
      end

      Resources.merge!({
        "t3.micro"     => InstanceResource.new(2, 4, nil),
        "t3.small"     => InstanceResource.new(2, 8, nil),
        "t3.medium"    => InstanceResource.new(2, 8, nil),
        "t3.large"     => InstanceResource.new(2, 8, nil),
        "t3.xlarge"    => InstanceResource.new(4, 16, nil),
        "t3.2xlarge"   => InstanceResource.new(4, 31, nil),
        "m5.large"     => InstanceResource.new(2, 8, nil),
        "m5.xlarge"    => InstanceResource.new(4, 16, nil),
        "m5.2xlarge"   => InstanceResource.new(8, 31, nil),
        "m5.4xlarge"   => InstanceResource.new(16, 60, nil),
        "m5.12xlarge"  => InstanceResource.new(48, 173, nil),
        "m5.24xlarge"  => InstanceResource.new(96, 345, nil),
        "m5a.large"    => InstanceResource.new(2, 8, nil),
        "m5a.xlarge"   => InstanceResource.new(4, 16, nil),
        "m5a.2xlarge"  => InstanceResource.new(8, 31, nil),
        "m5a.4xlarge"  => InstanceResource.new(16, 60, nil),
        "m5a.12xlarge" => InstanceResource.new(48, 173, nil),
        "m5a.24xlarge" => InstanceResource.new(96, 345, nil),
        "m5d.large"    => InstanceResource.new(2, 8, nil),
        "m5d.xlarge"   => InstanceResource.new(4, 16, nil),
        "m5d.2xlarge"  => InstanceResource.new(8, 31, nil),
        "m5d.4xlarge"  => InstanceResource.new(16, 60, nil),
        "m5d.12xlarge" => InstanceResource.new(48, 173, nil),
        "m5d.24xlarge" => InstanceResource.new(96, 345, nil),
        "c5.large"     => InstanceResource.new(2, 9, nil),
        "c5.xlarge"    => InstanceResource.new(4, 17, nil),
        "c5.2xlarge"   => InstanceResource.new(8, 34, nil),
        "c5.4xlarge"   => InstanceResource.new(16, 68, nil),
        "c5.9xlarge"   => InstanceResource.new(36, 141, nil),
        "c5.18xlarge"  => InstanceResource.new(72, 281, nil),
        "c5d.large"    => InstanceResource.new(2, 9, nil),
        "c5d.xlarge"   => InstanceResource.new(4, 17, nil),
        "c5d.2xlarge"  => InstanceResource.new(8, 34, nil),
        "c5d.4xlarge"  => InstanceResource.new(16, 68, nil),
        "c5d.9xlarge"  => InstanceResource.new(36, 141, nil),
        "c5d.18xlarge" => InstanceResource.new(72, 281, nil),
        "r5.large"     => InstanceResource.new(2, 10, nil),
        "r5.xlarge"    => InstanceResource.new(4, 19, nil),
        "r5.2xlarge"   => InstanceResource.new(8, 38, nil),
        "r5.4xlarge"   => InstanceResource.new(16, 71, nil),
        "r5.12xlarge"  => InstanceResource.new(48, 173, nil),
        "r5.24xlarge"  => InstanceResource.new(96, 347, nil),
        "r5a.large"    => InstanceResource.new(2, 10, nil),
        "r5a.xlarge"   => InstanceResource.new(4, 19, nil),
        "r5a.2xlarge"  => InstanceResource.new(8, 38, nil),
        "r5a.4xlarge"  => InstanceResource.new(16, 71, nil),
        "r5a.12xlarge" => InstanceResource.new(48, 173, nil),
        "r5a.24xlarge" => InstanceResource.new(96, 347, nil),
        "r5d.large"    => InstanceResource.new(2, 10, nil),
        "r5d.xlarge"   => InstanceResource.new(4, 19, nil),
        "r5d.2xlarge"  => InstanceResource.new(8, 38, nil),
        "r5d.4xlarge"  => InstanceResource.new(16, 71, nil),
        "r5d.12xlarge" => InstanceResource.new(48, 173, nil),
        "r5d.24xlarge" => InstanceResource.new(96, 347, nil),
        "i3.large"     => InstanceResource.new(2, 7, nil),
        "i3.xlarge"    => InstanceResource.new(4, 13, nil),
        "i3.2xlarge"   => InstanceResource.new(8, 27, nil),
        "i3.4xlarge"   => InstanceResource.new(16, 53, nil),
        "i3.8xlarge"   => InstanceResource.new(32, 99, nil),
        "i3.16xlarge"  => InstanceResource.new(64, 200, nil),
      })

      # attributes
      attr_accessor :recipe

      # new
      def initialize(recipe)
        self.recipe = recipe
      end

      def calculate(instance_size)
        if custom_pool_size > 0
          custom_pool_size
        else
          calculate_pool_size(instance_size)
        end
      end

      protected

      def settings
        @settings ||= Settings.new(self.recipe)
      end

      def ecu_count(instance_size)
        Resources[instance_size].ecus
      end

      def custom_pool_size
        pool_size = self.recipe.metadata_any_get(:pool_size)
        pool_size = self.recipe.fetch_env_var(
          self.recipe.node, pool_size_settings_key_to_env_var(:pool_size), pool_size)
        pool_size.to_i
      end

      def max_by_memory
        ((available_memory - settings[:reserved_memory]) / settings[:worker_memory_size]).floor
      end

      def max_by_ecu(instance_size)
        worker_count = (ecu_count(instance_size) * settings[:workers_per_ecu]).floor
        if self.recipe.node.engineyard.instance.role == "solo"
          worker_count - ([ ecu_count(instance_size), settings[:db_vcpu_max] ].min * settings[:db_workers_per_ecu]).floor
        else
          worker_count
        end
      end

      def calculate_pool_size(instance_size)
        apps_count = self.recipe.metadata_get_apps_count
        smallest_of_maximums = [ max_by_memory, max_by_ecu(instance_size), settings[:max_pool_size] ].min
        pool_size = ([ smallest_of_maximums, settings[:min_pool_size] ].max / apps_count).floor

        # ensure pool_size is never zero
        if pool_size == 0
          pool_size  = 1
        else
          pool_size
        end
      end

      def available_memory
        meminfo = File.read("/proc/meminfo")
        memory = meminfo[/^MemTotal:\s+(\d+)/, 1].to_i / 1024
        swap = meminfo[/^SwapTotal:\s+(\d+)/, 1].to_i / 1024
        memory + (swap * settings[:swap_usage_percent] / 100).floor
      end
    end

    def self.instance_resources(instance_size)
      Engineyard::PoolSize::Calculator::Resources[instance_size]
    end
  end
end

module PoolSizeCalculator
  module Helper
    def get_pool_size
      @pool_size ||= begin
        pool_size = Engineyard::PoolSize::Calculator.new(self).calculate(node.ec2_instance_size)
        Chef::Log.info "Worker pool size: #{pool_size}"
        pool_size
      end
    end
  end
end

class Chef
  class Recipe
    include PoolSizeCalculator::Helper
  end
end