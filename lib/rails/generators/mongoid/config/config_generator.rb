# encoding: utf-8
require 'rails/generators/mongoid_generator'

module Mongoid
  module Generators

    class ConfigGenerator < Rails::Generators::Base
      desc "Creates a Mongoid configuration file at config/database.mongo.yml"
      
      argument :database_name, :type => :string, :optional => true
      
      def self.source_root
        @_mongoid_source_root ||= File.expand_path("../templates", __FILE__)
      end
      
      def app_name
        Rails::Application.subclasses.first.parent.to_s.underscore
      # rescue
      #   "app"
      end
      
      def create_config_file
        template 'database.mongo.yml', File.join('config', "database.mongo.yml")
      end
      
    end

  end
end
