# frozen_string_literal: true

class Simple
  include Mongoid::Document
  field :name, type: :string
  scope :nothing, -> { none }
end
