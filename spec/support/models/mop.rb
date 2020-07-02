# frozen_string_literal: true
# encoding: utf-8

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
end
