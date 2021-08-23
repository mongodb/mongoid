# frozen_string_literal: true

require 'rails/generators/mongoid_generator'

module Mongoid
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc "Creates a Mongoid configuration file at config/mongoid.yml"

      argument :database_name, type: :string, optional: true

      def self.source_root
        @_mongoid_source_root ||= File.expand_path("../templates", __FILE__)
      end

      def app_name
        app_cls = Rails.application.class
        parent = begin
          # Rails 6.1+
          app_cls.module_parent_name
        rescue NoMethodError
          app_cls.parent.to_s
        end
        parent.underscore
      end

      def create_config_file
        template 'mongoid.yml', File.join('config', "mongoid.yml")
      end

    end
  end
end
