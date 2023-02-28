# frozen_string_literal: true

module Mongoid
  module Fields

    # Singleton module which contains a mapping of field types to field class.
    # Custom field types can be configured.
    #
    # @api private
    module FieldTypes

      # The default mapping of field type symbol/string identifiers to classes.
      #
      # @api private
      DEFAULT_MAPPING = {
        array: Array,
        big_decimal: BigDecimal,
        binary: BSON::Binary,
        boolean: Mongoid::Boolean,
        date: Date,
        date_time: DateTime,
        #decimal128: BSON::Decimal128,
        float: Float,
        hash: Hash,
        integer: Integer,
        #object: Object,
        object_id: BSON::ObjectId,
        range: Range,
        regexp: Regexp,
        set: Set,
        string: String,
        stringified_symbol: Mongoid::StringifiedSymbol,
        symbol: Symbol,
        time: Time,
        #time_with_zone: ActiveSupport::TimeWithZone,
      }.with_indifferent_access.freeze

      class << self

        # Resolves the user-provided field type to the field type class.
        #
        # @example
        #   Mongoid::FieldTypes.get(:point)
        #
        # @param [ Module | Symbol | String ] field_type The field
        #   type class or its string or symbol identifier.
        #
        # @return [ Module | nil ] The underlying field type class, or nil if
        #   string or symbol was passed and it is not mapped to any class.
        def get(field_type)
          case field_type
          when Module
            module_field_type(field_type)
          when Symbol, String
            mapping[field_type]
          end
        end

        # Defines a field type mapping, for later use in field :type option.
        #
        # @example
        #   Mongoid::FieldTypes.define_type(:point, Point)
        #
        # @param [ Symbol | String ] field_type The identifier of the
        #   defined type. This identifier may be accessible as either a
        #   Symbol or a String regardless of the type passed to this method.
        # @param [ Class ] klass the class of the defined type, which must
        #   include mongoize, demongoize, and evolve methods.
        def define_type(field_type, klass)
          unless (field_type.is_a?(String) || field_type.is_a?(Symbol)) && klass.is_a?(Module)
            raise Mongoid::Errors::InvalidFieldTypeDefinition.new(field_type, klass)
          end
          mapping[field_type] = klass
        end

        delegate :delete, to: :mapping

        # The memoized mapping of field type definitions to classes.
        #
        # @return [ ActiveSupport::HashWithIndifferentAccess<Symbol, Class> ] The memoized field mapping.
        def mapping
          @mapping ||= DEFAULT_MAPPING.dup
        end

        private

        def module_field_type(field_type)
          return Mongoid::Boolean if field_type.to_s == "Boolean"
          field_type
        end
      end
    end
  end
end
