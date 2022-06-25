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

    def restore_config_clients
      around do |example|
        # Duplicate the config because some tests mutate it.
        old_config = Mongoid::Config.clients.dup
        example.run
        Mongoid::Config.send(:clients=, old_config)
      end
    end
  end
end
