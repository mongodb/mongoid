# frozen_string_literal: true

class Kaleidoscope
  include Mongoid::Document
  field :active, type: :boolean, default: true

  scope :activated, -> { where(active: true) }
end
