# encoding: utf-8
if defined?(Rails::Railtie)
  module Rails #:nodoc:
    module Mongoid #:nodoc:
      class Railtie < Rails::Railtie

        # do we want a custom log subscriber for mongoid?
        # log_subscriber :mongoid, ::Mongoid::Railties::LogSubscriber.new

        config.generators.orm :mongoid, :migration => false

        rake_tasks do
          load "mongoid/railties/database.rake"
        end

        initializer "setup database" do
          config_file = Rails.root.join("config", "mongoid.yml")
          if config_file.file?
            settings = YAML.load(ERB.new(config_file.read).result)[Rails.env]
            if settings.present?
              ::Mongoid.configure do |config|
                database = settings["database"]
                host = settings["host"]
                port = settings["port"]
                config.master = Mongo::Connection.new(host, port).db(database)

                if settings.has_key?("allow_dynamic_fields")
                  config.allow_dynamic_fields = !!settings["allow_dynamic_fields"]
                end

                if settings.has_key?("max_successive_reads")
                  config.max_successive_reads = settings["max_successive_reads"].to_i
                end

                if settings.has_key?("parameterize_keys")
                  config.parameterize_keys = !!settings["parameterize_keys"]
                end

                if settings.has_key?("persist_in_safe_mode")
                  config.persist_in_safe_mode = !!settings["persist_in_safe_mode"]
                end

                if settings.has_key?("raise_not_found_error")
                  config.raise_not_found_error = !!settings["raise_not_found_error"]
                end

                if settings.has_key?("reconnect_time")
                  config.reconnect_time = settings["reconnect_time"].to_i
                end

                config.slaves = []
                settings["slaves"].to_a.each do |slave_config|
                  config.slaves << Mongo::Connection.new(
                    slave_config["host"] || host,
                    slave_config["port"] || port,
                    :slave_ok => true
                  ).db(database)
                end
              end
            end
          end
        end

        initializer "verify that mongoid is configured" do
          config.after_initialize do
            begin
              ::Mongoid.master
            rescue ::Mongoid::Errors::InvalidDatabase => e
              unless Rails.root.join("config", "mongoid.yml").file?
                puts "\nMongoid config not found. Create a config file at: config/mongoid.yml"
                puts "to generate one run: script/rails generate mongoid:config\n\n"
              end
            end
          end
        end
      end
    end
  end
end
