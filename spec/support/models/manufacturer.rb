# frozen_string_literal: true

class Manufacturer
  include Mongoid::Document

  field :products, type: :array, default: []

  validates_presence_of :products
end
