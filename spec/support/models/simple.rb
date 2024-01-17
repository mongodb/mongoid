# frozen_string_literal: true
# rubocop:todo all

class Simple
  include Mongoid::Document
  field :name, type: String
  scope :nothing, -> { none }
end
