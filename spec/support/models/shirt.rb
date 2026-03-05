# frozen_string_literal: true
# rubocop:todo all

class Shirt
  include Mongoid::Document

  field :color, type: String

  unalias_attribute :id

  field :id, type: String
end
