# frozen_string_literal: true

class Simple
  include Mongoid::Document
  field :name, type: String
  scope :nothing, -> { none }
end
