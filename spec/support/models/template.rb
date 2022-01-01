# frozen_string_literal: true

class Template
  include Mongoid::Document
  field :active, type: :boolean, default: false
  validates :active, presence: true
end
