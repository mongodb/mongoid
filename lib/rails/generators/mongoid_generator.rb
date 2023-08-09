# frozen_string_literal: true
# rubocop:todo all

require "rails/generators/named_base"
require "rails/generators/active_model"

module Mongoid
  module Generators

    # Base generator class for adding Mongoid to Rails applications.
    class Base < ::Rails::Generators::NamedBase

      # Returns the path to the templates directory.
      #
      # @return [ String ] The path.
      def self.source_root
        @_mongoid_source_root ||=
          File.expand_path("../#{base_name}/#{generator_name}/templates", __FILE__)
      end
    end
  end
end

module Rails
  module Generators

    # Extension to Rails' GeneratedAttribute class.
    class GeneratedAttribute

      # Returns the Mongoid attribute type value for a given
      # input class type.
      #
      # @return [ String ] The type value.
      def type_class
        return "Time" if type == :datetime
        return "String" if type == :text
        return "Mongoid::Boolean" if type == :boolean
        type.to_s.camelcase
      end
    end
  end
end
