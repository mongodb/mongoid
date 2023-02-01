# frozen_string_literal: true

require 'rails/generators/mongoid_generator'

module Mongoid
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc "Creates Mongoid configuration files"

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
        template 'mongoid.yml', File.join('config', 'mongoid.yml')
      end

      def create_initializer_file
        template 'mongoid.rb', File.join('config', 'initializers', 'mongoid.rb')
      end

      private

      # Extracts the available configuration options from the Mongoid::Config
      # source file, and returns them as an array of hashes.
      #
      # @param [ Integer ] indent How many spaces each comment ought to
      #   be re-indented.
      # @param [ true | false ] include_deprecated Whether deprecated options
      #   should be included in the list.
      #
      # @return [ Array<Hash<desc: [String], name: [String], default: [String],
      #   deprecated: [nil | Integer]>> ] the array of hashes representing
      #   each defined option, in alphabetical order by name.
      def mongoid_config_options(indent: 2, include_deprecated: false)
        module_location = File.absolute_path(
          File.join(
            File.dirname(__FILE__),
            "../../../../mongoid/config.rb"))

        src = File.read(module_location)
        src.scan(/(((?:\s*#.*\n)+)\s+option :(\w+), default: (.*)\n)/)
          .map { |opt| { desc: reindent(opt[1], indent), name: opt[2], default: opt[3], deprecated: opt[1] =~ /\(Deprecated\)/ } }
          .reject { |opt| !include_deprecated && opt[:deprecated] }
          .sort_by { |opt| opt[:name] }
      end

      # Reindents the given text, using the given indentation size.
      #
      # @param [ String ] text The text to reindent
      # @param [ Integer ] indent_size The number of spaces to use for the
      #   new indentation
      #
      # @return [ String ] the text, re-indented.
      def reindent(text, indent_size)
        indentation = " " * indent_size
        text.gsub(/^\s+/, indentation)
      end
    end
  end
end
