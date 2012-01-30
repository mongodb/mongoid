# encoding: utf-8
module Mongoid #:nodoc
  module Fields #:nodoc:

    module Internal #:nodoc:
    end

    # This module maps classes used in field type definitions to the custom
    # definable field in Mongoid.
    module Mappings
      extend self

      MODULE = Mongoid::Fields::Internal

      # Get the custom field type for the provided class used in the field
      # definition.
      #
      # @example Get the mapping for the class.
      #   Mappings.for(BSON::ObjectId)
      #
      # @param [ Class ] klass The class to get the field type for.
      #
      # @return [ Class ] The class of the custom field.
      #
      # @since 2.1.0
      def for(klass, foreign_key = false)
        return Internal::Object unless klass
        if foreign_key
          return MODULE::ForeignKeys.const_get(klass.to_s.demodulize)
        end
        begin
          modules = "#{ MODULE }::|BSON::|ActiveSupport::"
          if match = klass.to_s.match(Regexp.new("^(#{ modules })?(\\w+)$"))
            MODULE.const_get(match[2])
          else
            klass
          end
        rescue NameError
          klass
        end
      end
    end
  end
end
