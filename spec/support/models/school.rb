# frozen_string_literal: true

class School
  include Mongoid::Document

  has_many :students

  field :district, type: String
  field :team, type: String

  field :after_destroy_triggered, default: false

  accepts_nested_attributes_for :students, allow_destroy: true
end
