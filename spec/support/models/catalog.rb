# frozen_string_literal: true

class Catalog
  include Mongoid::Document

  field :array_field, type: Array
  field :big_decimal_field, type: BigDecimal
  field :boolean_field, type: Boolean
  field :date_field, type: Date
  field :date_time_field, type: DateTime
  field :float_field, type: Float
  field :hash_field, type: Hash
  field :integer_field, type: Integer
  field :object_id_field, type: BSON::ObjectId
  field :binary_field, type: BSON::Binary
  field :range_field, type: Range
  field :regexp_field, type: Regexp
  field :set_field, type: Set
  field :string_field, type: String
  field :stringified_symbol_field, type: StringifiedSymbol
  field :symbol_field, type: Symbol
  field :time_field, type: Time
  field :time_with_zone_field, type: ActiveSupport::TimeWithZone
end
