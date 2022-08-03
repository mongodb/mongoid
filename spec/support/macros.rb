# frozen_string_literal: true

module Mongoid
  module Macros
    class I18nBackendWithFallbacks < I18n::Backend::Simple
      include I18n::Backend::Fallbacks
    end

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

    def with_i18n_fallbacks
      require_fallbacks

      around do |example|
        old_backend = I18n.backend
        I18n.backend = I18nBackendWithFallbacks.new
        example.run
      ensure
        I18n.backend = old_backend
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
  end
end
