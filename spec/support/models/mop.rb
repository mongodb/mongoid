# frozen_string_literal: true

# This class is used for embedded matcher testing.
class Mop
  include Mongoid::Document

  # The dynamic attributes are used so that the tests can use various
  # field names as makes sense for the particular operator.
  include Mongoid::Attributes::Dynamic

  # We need some fields of specific types because the query conditions are
  # transformed differently based on the type of field being queried.
  field :int_field, type: Integer
  field :array_field, type: Array
  field :date_field, type: Date
  field :time_field, type: Time
  field :datetime_field, type: DateTime
  field :big_decimal_field, type: BigDecimal
  field :decimal128_field, type: BSON::Decimal128
  field :symbol_field, type: Symbol
  field :bson_symbol_field, type: BSON::Symbol::Raw
  field :regexp_field, type: Regexp
  field :bson_regexp_field, type: BSON::Regexp::Raw
end
