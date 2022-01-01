# frozen_string_literal: true

module Mongoid

  # Singleton module which contains a cache for field type definitions.
  # Custom field types can be configured.
  module FieldTypes
    extend self

    # For fields defined with symbols use the correct class.
    DEFAULT_MAPPING = {
      array: Array,
      bigdecimal: BigDecimal,
      big_decimal: BigDecimal,
      binary: BSON::Binary,
      boolean: Mongoid::Boolean,
      date: Date,
      datetime: DateTime,
      date_time: DateTime,
      decimal128: BSON::Decimal128,
      double: Float,
      float: Float,
      hash: Hash,
      integer: Integer,
      object: Object,
      object_id: BSON::ObjectId,
      range: Range,
      regexp: Regexp,
      set: Set,
      string: String,
      stringified_symbol: Mongoid::StringifiedSymbol,
      symbol: Symbol,
      time: Time,
      time_with_zone: ActiveSupport::TimeWithZone
    }.with_indifferent_access.freeze

    def get(value)
      mapping[value] || handle_unmapped_type(value)
    end

    def define(symbol, klass)
      mapping[symbol] = klass
    end

    delegate :delete, to: :mapping

    def mapping
      @mapping ||= DEFAULT_MAPPING.dup
    end

    def handle_unmapped_type(type)
      return Object if type.nil?

      if type.is_a?(Module)
        Mongoid.logger.warn(FIELD_TYPE_IS_SYMBOL)
        return Mongoid::Boolean if type.to_s == 'Boolean'
        type
      end

      nil
    end
  end
end
