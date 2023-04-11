# frozen_string_literal: true

module Mongoid
  module Macros

    def use_spec_mongoid_config
      around do |example|
        config_path = File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")

        Mongoid::Clients.clear
        Mongoid.load!(config_path, :test)

        begin
          example.run
        ensure
          Mongoid::Config.reset
        end
      end
    end

    def config_override(key, value)
      around do |example|
        existing = Mongoid.send(key)

        Mongoid.send("#{key}=", value)

        example.run

        Mongoid.send("#{key}=", existing)
      end
    end

    def with_config_values(key, *values, &block)
      values.each do |value|
        context "when #{key} is #{value}" do
          config_override key, value

          class_exec(value, &block)
        end
      end
    end

    def driver_config_override(key, value)
      around do |example|
        existing = Mongo.send(key)

        Mongo.send("#{key}=", value)

        example.run

        Mongo.send("#{key}=", existing)
      end
    end

    def with_driver_config_values(key, *values, &block)
      values.each do |value|
        context "when #{key} is #{value}" do
          driver_config_override key, value

          class_exec(value, &block)
        end
      end
    end

    def restore_config_clients
      around do |example|
        # Duplicate the config because some tests mutate it.
        old_config = Mongoid::Config.clients.dup
        example.run
        Mongoid::Config.send(:clients=, old_config)
      end
    end

    def query_cache_enabled
      around do |example|
        Mongoid::QueryCache.cache do
          example.run
        end
      end
    end

    def override_query_cache(enabled)
      around do |example|
        cache_enabled = Mongo::QueryCache.enabled?
        Mongo::QueryCache.enabled = enabled
        example.run
        Mongo::QueryCache.enabled = cache_enabled
      end
    end

    # Override the global persistence context.
    #
    # @param [ :client, :database ] component The component to override.
    # @param [ Object ] value The value to override to.
    def persistence_context_override(component, value)
      around do |example|
        meth = "#{component}_override"
        old_value = Mongoid::Threaded.send(meth)
        Mongoid::Threaded.send("#{meth}=", value)
        example.run
        Mongoid::Threaded.send("#{meth}=", old_value)
      end
    end

    def time_zone_override(tz)
      around do |example|
        old_tz = Time.zone
        Time.zone = tz
        example.run
        Time.zone = old_tz
      end
    end

    def with_default_i18n_configs
      around do |example|
        I18n.locale = :en
        I18n.default_locale = :en
        I18n.try(:fallbacks=, I18n::Locale::Fallbacks.new)
        I18n.enforce_available_locales = false
        example.run
      ensure
        I18n.locale = :en
        I18n.default_locale = :en
        I18n.try(:fallbacks=, I18n::Locale::Fallbacks.new)
        I18n.enforce_available_locales = false
      end
    end
  end
end
