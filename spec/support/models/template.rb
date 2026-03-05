# frozen_string_literal: true
# rubocop:todo all

class Template
  include Mongoid::Document
  field :active, type: Mongoid::Boolean, default: false
  validates :active, presence: true
end
