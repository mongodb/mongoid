# frozen_string_literal: true
# encoding: utf-8

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
  end
end
