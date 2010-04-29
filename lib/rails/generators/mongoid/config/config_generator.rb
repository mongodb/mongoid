# encoding: utf-8
require 'rails/generators/mongoid_generator'

module Mongoid
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc "Creates a Mongoid configuration file at config/mongoid.yml"

      argument :database_name, :type => :string, :optional => true

      def self.source_root
        @_mongoid_source_root ||= File.expand_path("../templates", __FILE__)
      end

      def app_name
        Rails::Application.subclasses.first.parent.to_s.underscore
      end

      def create_config_file
        template 'mongoid.yml', File.join('config', "mongoid.yml")
      end

      def inject_mongoid_into_application
        config_application_path = File.join("config", "application.rb")
        config_contents = File.read(config_application_path)

        mongoid_require = "\n\nrequire 'mongoid/railtie'"

        # check to see if its already been included
        return if config_contents.include?(mongoid_require)

        if config_contents.include?("require 'rails/all'")
          inject_into_file config_application_path, mongoid_require, :after => "require 'rails/all'"
        elsif config_contents.include?("require \"action_controller/railtie\"")
          inject_into_file config_application_path, mongoid_require, :after => "require \"action_controller/railtie\""
        end
      end

    end
  end
end
