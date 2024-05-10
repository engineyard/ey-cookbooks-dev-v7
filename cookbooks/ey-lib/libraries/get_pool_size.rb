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
      MEMORY_CONVERSION_FACTOR = 1024
      DEFAULT_POOL_SIZE = 1

      # Constants for repeated values
      VCPU_LARGE = 2
      VCPU_XLARGE = 4
      VCPU_2XLARGE = 8
      VCPU_4XLARGE = 16
      VCPU_8XLARGE = 32
      VCPU_9XLARGE = 36
      VCPU_12XLARGE = 48
      VCPU_16XLARGE = 64
      VCPU_18XLARGE = 72
      VCPU_24XLARGE = 96
      VCPU_32XLARGE = 128
      VCPU_48XLARGE = 192

      # Then use these constants in the method calls
      add_instance_resources("m6a.large", VCPU_LARGE, 12)
      add_instance_resources("m6a.xlarge", VCPU_XLARGE, 24)

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

      def self.add_instance_resources(instance_type, vcpus, defined_ecus=nil, innodb_pool=nil)
        Resources[instance_type] = InstanceResource.new(vcpus, defined_ecus, innodb_pool)
      end

      Resources = Hash.new do |h, k|
        # parse cpuinfo and count the number of cores that it reports; use that as a default if asked for an unknown instance size.
        cores = File.read("/proc/cpuinfo").scan(/processor\s*:.*?cpu\s+cores\s*:\s*(\d+)/m).inject(0) { |a, x| a += x.first.to_i }
        h[k] = InstanceResource.new(cores, nil, nil)
      end

      # General burstable 3rd Gen
      add_instance_resources("t3.micro", VCPU_LARGE, 10)
      add_instance_resources("t3.small", VCPU_LARGE, 10)
      add_instance_resources("t3.medium", VCPU_LARGE, 10)
      add_instance_resources("t3.large", VCPU_LARGE, 10)
      add_instance_resources("t3.xlarge", VCPU_XLARGE, 16)
      add_instance_resources("t3.2xlarge", VCPU_2XLARGE, 37)

      # General purpose 5th Gen
      add_instance_resources("m5.large", VCPU_LARGE, 10)
      add_instance_resources("m5.xlarge", VCPU_XLARGE, 16)
      add_instance_resources("m5.2xlarge", VCPU_2XLARGE, 37)
      add_instance_resources("m5.4xlarge", VCPU_4XLARGE, 70)
      add_instance_resources("m5.12xlarge", VCPU_12XLARGE, 168)
      add_instance_resources("m5.24xlarge", VCPU_24XLARGE, 337)
      add_instance_resources("m5a.large", VCPU_LARGE, 10)
      add_instance_resources("m5a.xlarge", VCPU_XLARGE, 16)
      add_instance_resources("m5a.2xlarge", VCPU_2XLARGE, 37)
      add_instance_resources("m5a.4xlarge", VCPU_4XLARGE, 70)
      add_instance_resources("m5a.12xlarge", VCPU_12XLARGE, 168)
      add_instance_resources("m5a.24xlarge", VCPU_24XLARGE, 337)
      add_instance_resources("m5d.large", VCPU_LARGE, 10)
      add_instance_resources("m5d.xlarge", VCPU_XLARGE, 16)
      add_instance_resources("m5d.2xlarge", VCPU_2XLARGE, 37)
      add_instance_resources("m5d.4xlarge", VCPU_4XLARGE, 70)
      add_instance_resources("m5d.12xlarge", VCPU_12XLARGE, 168)
      add_instance_resources("m5d.24xlarge", VCPU_24XLARGE, 337)

      # General purpose 6th Gen
      add_instance_resources("m6a.large", VCPU_LARGE, 12)
      add_instance_resources("m6a.xlarge", VCPU_XLARGE, 19)
      add_instance_resources("m6a.2xlarge", VCPU_2XLARGE, 44)
      add_instance_resources("m6a.4xlarge", VCPU_4XLARGE, 84)
      add_instance_resources("m6a.12xlarge", VCPU_12XLARGE, 201)
      add_instance_resources("m6a.24xlarge", VCPU_24XLARGE, 404)
      add_instance_resources("m6i.large", VCPU_LARGE, 12)
      add_instance_resources("m6i.xlarge", VCPU_XLARGE, 19)
      add_instance_resources("m6i.2xlarge", VCPU_2XLARGE, 44)
      add_instance_resources("m6i.4xlarge", VCPU_4XLARGE, 84)
      add_instance_resources("m6i.12xlarge", VCPU_12XLARGE, 201)
      add_instance_resources("m6i.24xlarge", VCPU_24XLARGE, 307)
      add_instance_resources("m6g.large", VCPU_LARGE, 14)
      add_instance_resources("m6g.xlarge", VCPU_XLARGE, 22)
      add_instance_resources("m6g.2xlarge", VCPU_2XLARGE, 52)
      add_instance_resources("m6g.4xlarge", VCPU_4XLARGE, 100)
      add_instance_resources("m6g.12xlarge", VCPU_12XLARGE, 241)
      add_instance_resources("m6g.16xlarge", VCPU_16XLARGE, 484)
      add_instance_resources("m6gd.large", VCPU_LARGE, 14)
      add_instance_resources("m6gd.xlarge", VCPU_XLARGE, 22)
      add_instance_resources("m6gd.2xlarge", VCPU_2XLARGE, 52)
      add_instance_resources("m6gd.4xlarge", VCPU_4XLARGE, 100)
      add_instance_resources("m6gd.12xlarge", VCPU_12XLARGE, 241)
      add_instance_resources("m6gd.16xlarge", VCPU_16XLARGE, 484)

      # Compute optimized 5th Gen
      add_instance_resources("c5.large", VCPU_LARGE, 10)
      add_instance_resources("c5.xlarge", VCPU_XLARGE, 20)
      add_instance_resources("c5.2xlarge", VCPU_2XLARGE, 39)
      add_instance_resources("c5.4xlarge", VCPU_4XLARGE, 73)
      add_instance_resources("c5.9xlarge", VCPU_9XLARGE, 139)
      add_instance_resources("c5.18xlarge", VCPU_18XLARGE, 281)
      add_instance_resources("c5d.large", VCPU_LARGE, 10)
      add_instance_resources("c5d.xlarge", VCPU_XLARGE, 20)
      add_instance_resources("c5d.2xlarge", VCPU_2XLARGE, 39)
      add_instance_resources("c5d.4xlarge", VCPU_4XLARGE, 73)
      add_instance_resources("c5d.9xlarge", VCPU_9XLARGE, 139)
      add_instance_resources("c5d.18xlarge", VCPU_18XLARGE, 281)

      # Compute optimized 6th Gen
      add_instance_resources("c6i.large", VCPU_LARGE, 12)
      add_instance_resources("c6i.xlarge", VCPU_XLARGE, 24)
      add_instance_resources("c6i.2xlarge", VCPU_2XLARGE, 46)
      add_instance_resources("c6i.4xlarge", VCPU_4XLARGE, 87)
      add_instance_resources("c6i.8xlarge", VCPU_8XLARGE, 174)
      add_instance_resources("c6i.16xlarge", VCPU_16XLARGE, 348)
      add_instance_resources("c6a.large", VCPU_LARGE, 12)
      add_instance_resources("c6a.xlarge", VCPU_XLARGE, 24)
      add_instance_resources("c6a.2xlarge", VCPU_2XLARGE, 46)
      add_instance_resources("c6a.4xlarge", VCPU_4XLARGE, 87)
      add_instance_resources("c6a.8xlarge", VCPU_8XLARGE, 174)
      add_instance_resources("c6a.16xlarge", VCPU_16XLARGE, 348)
      add_instance_resources("c6g.large", VCPU_LARGE, 14)
      add_instance_resources("c6g.xlarge", VCPU_XLARGE, 28)
      add_instance_resources("c6g.2xlarge", VCPU_2XLARGE, 55)
      add_instance_resources("c6g.4xlarge", VCPU_4XLARGE, 104)
      add_instance_resources("c6g.8xlarge", VCPU_8XLARGE, 208)
      add_instance_resources("c6g.16xlarge", VCPU_16XLARGE, 417)
      add_instance_resources("c6gd.large", VCPU_LARGE, 14)
      add_instance_resources("c6gd.xlarge", VCPU_XLARGE, 28)
      add_instance_resources("c6gd.2xlarge", VCPU_2XLARGE, 55)
      add_instance_resources("c6gd.4xlarge", VCPU_4XLARGE, 104)
      add_instance_resources("c6gd.8xlarge", VCPU_8XLARGE, 208)
      add_instance_resources("c6gd.16xlarge", VCPU_16XLARGE, 417)

      # Memory optimized 5th Gen
      add_instance_resources("r5.large", VCPU_LARGE, 10)
      add_instance_resources("r5.xlarge", VCPU_XLARGE, 19)
      add_instance_resources("r5.2xlarge", VCPU_2XLARGE, 37)
      add_instance_resources("r5.4xlarge", VCPU_4XLARGE, 70)
      add_instance_resources("r5.12xlarge", VCPU_12XLARGE, 168)
      add_instance_resources("r5.24xlarge", VCPU_24XLARGE, 337)
      add_instance_resources("r5a.large", VCPU_LARGE, 10)
      add_instance_resources("r5a.xlarge", VCPU_XLARGE, 19)
      add_instance_resources("r5a.2xlarge", VCPU_2XLARGE, 37)
      add_instance_resources("r5a.4xlarge", VCPU_4XLARGE, 70)
      add_instance_resources("r5a.12xlarge", VCPU_12XLARGE, 168)
      add_instance_resources("r5a.24xlarge", VCPU_24XLARGE, 337)
      add_instance_resources("r5d.large", VCPU_LARGE, 10)
      add_instance_resources("r5d.xlarge", VCPU_XLARGE, 19)
      add_instance_resources("r5d.2xlarge", VCPU_2XLARGE, 37)
      add_instance_resources("r5d.4xlarge", VCPU_4XLARGE, 70)
      add_instance_resources("r5d.12xlarge", VCPU_12XLARGE, 168)
      add_instance_resources("r5d.24xlarge", VCPU_24XLARGE, 337)

      # Memory optimized 6th Gen
      add_instance_resources("r6a.large", VCPU_LARGE, 12)
      add_instance_resources("r6a.xlarge", VCPU_XLARGE, 24)
      add_instance_resources("r6a.2xlarge", VCPU_2XLARGE, 48)
      add_instance_resources("r6a.4xlarge", VCPU_4XLARGE, 96)
      add_instance_resources("r6a.12xlarge", VCPU_12XLARGE, 224)
      add_instance_resources("r6a.16xlarge", VCPU_16XLARGE, 316)
      add_instance_resources("r6a.24xlarge", VCPU_24XLARGE, 444)
      add_instance_resources("r6a.32xlarge", VCPU_32XLARGE, 535)
      add_instance_resources("r6a.48xlarge", VCPU_48XLARGE, 768)
      add_instance_resources("r6i.large", VCPU_LARGE, 12)
      add_instance_resources("r6i.xlarge", VCPU_XLARGE, 22)
      add_instance_resources("r6i.2xlarge", VCPU_2XLARGE, 44)
      add_instance_resources("r6i.4xlarge", VCPU_4XLARGE, 84)
      add_instance_resources("r6i.12xlarge", VCPU_12XLARGE, 201)
      add_instance_resources("r6i.24xlarge", VCPU_24XLARGE, 404)
      add_instance_resources("r6g.large", VCPU_LARGE, 14)
      add_instance_resources("r6g.xlarge", VCPU_XLARGE, 26)
      add_instance_resources("r6g.2xlarge", VCPU_2XLARGE, 52)
      add_instance_resources("r6g.4xlarge", VCPU_4XLARGE, 100)
      add_instance_resources("r6g.12xlarge", VCPU_12XLARGE, 241)
      add_instance_resources("r6g.16xlarge", VCPU_16XLARGE, 368)
      add_instance_resources("r6gd.large", VCPU_LARGE, 14)
      add_instance_resources("r6gd.xlarge", VCPU_XLARGE, 26)
      add_instance_resources("r6gd.2xlarge", VCPU_2XLARGE, 52)
      add_instance_resources("r6gd.4xlarge", VCPU_4XLARGE, 100)
      add_instance_resources("r6gd.12xlarge", VCPU_12XLARGE, 241)
      add_instance_resources("r6gd.16xlarge", VCPU_16XLARGE, 368)

      # Storage optimized 3rd Gen
      add_instance_resources("i3.large", VCPU_LARGE, 8)
      add_instance_resources("i3.xlarge", VCPU_XLARGE, 16)
      add_instance_resources("i3.2xlarge", VCPU_2XLARGE, 31)
      add_instance_resources("i3.4xlarge", VCPU_4XLARGE, 58)
      add_instance_resources("i3.8xlarge", VCPU_8XLARGE, 97)
      add_instance_resources("i3.16xlarge", VCPU_16XLARGE, 201)

      # Storage optimized 4rd Gen
      add_instance_resources("i4i.large", VCPU_LARGE, 8)
      add_instance_resources("i4i.xlarge", VCPU_XLARGE, 16)
      add_instance_resources("i4i.2xlarge", VCPU_2XLARGE, 31)
      add_instance_resources("i4i.4xlarge", VCPU_4XLARGE, 58)
      add_instance_resources("i4i.8xlarge", VCPU_8XLARGE, 97)
      add_instance_resources("i4i.16xlarge", VCPU_16XLARGE, 201)

      # attributes
      attr_accessor :recipe

      # new
      def initialize(recipe)
        self.recipe = recipe
      end

      def calculate(instance_size)
        custom_pool_size > 0 ? custom_pool_size : calculate_pool_size(instance_size)
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
        pool_size = calculate_pool_size_based_on_apps_count(instance_size)
        ensure_pool_size_is_never_zero(pool_size)
      end

      def calculate_pool_size_based_on_apps_count(instance_size)
        apps_count = self.recipe.metadata_get_apps_count
        smallest_of_maximums = [ max_by_memory, max_by_ecu(instance_size), settings[:max_pool_size] ].min
        ([ smallest_of_maximums, settings[:min_pool_size] ].max / apps_count).floor
      end

      def ensure_pool_size_is_never_zero(pool_size)
        pool_size.zero? ? DEFAULT_POOL_SIZE : pool_size
      end

      def available_memory
        meminfo = read_meminfo_file
        memory = meminfo[/^MemTotal:\s+(\d+)/, 1].to_i / MEMORY_CONVERSION_FACTOR
        swap = meminfo[/^SwapTotal:\s+(\d+)/, 1].to_i / MEMORY_CONVERSION_FACTOR
        memory + (swap * settings[:swap_usage_percent] / 100).floor
      end

      def read_meminfo_file
        File.read("/proc/meminfo")
      rescue Errno::ENOENT
        # Handle error, e.g. log it and/or raise a custom error
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
