# encoding: utf-8
module Mongoid #:nodoc
  module Fields #:nodoc:

    # This module maps classes used in field type definitions to the custom
    # definable field in Mongoid.
    module Mappings
      extend self

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
        return Serializable::Object unless klass
        return Serializable::ObjectId if klass == BSON::ObjectId
        return Serializable::TimeWithZone if klass == ActiveSupport::TimeWithZone
        return Serializable::ForeignKeys::Array if foreign_key
        begin
          "Mongoid::Fields::Serializable::#{klass}".constantize
        rescue NameError
          klass
        end
      end
    end
  end
end
