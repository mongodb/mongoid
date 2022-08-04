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

    def with_i18n_fallbacks
      require_fallbacks

      around do |example|
        include I18n::Backend::Fallbacks
        if I18n.respond_to?(:temp_fallbacks)
          class << I18n
            alias :fallbacks :temp_fallbacks
            alias :fallbacks= :temp_fallbacks=
            undef_method :temp_fallbacks
            undef_method :temp_fallbacks=
          end
        end
        example.run
      ensure
        class << I18n
          alias :temp_fallbacks :fallbacks
          alias :temp_fallbacks= :fallbacks=
          undef_method :fallbacks
          undef_method :fallbacks=
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
