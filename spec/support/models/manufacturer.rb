# frozen_string_literal: true
# rubocop:todo all

class Manufacturer
  include Mongoid::Document

  field :products, type: Array, default: []

  validates_presence_of :products
end
