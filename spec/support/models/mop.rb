# frozen_string_literal: true

# This class is used for embedded matcher testing.
class Mop
  include Mongoid::Document

  # The dynamic attributes are used so that the tests can use various
  # field names as makes sense for the particular operator.
  include Mongoid::Attributes::Dynamic

  # We need some fields of specific types because the query conditions are
  # transformed differently based on the type of field being queried.
  field :int_field, type: :integer
  field :array_field, type: :array
  field :date_field, type: :date
  field :time_field, type: :time
  field :datetime_field, type: :date_time
  field :big_decimal_field, type: :big_decimal
  field :decimal128_field, type: :decimal128
  field :symbol_field, type: :symbol
  field :bson_symbol_field, type: :bson_symbol
  field :regexp_field, type: :regexp
  field :bson_regexp_field, type: :bson_regexp
end
