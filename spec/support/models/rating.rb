# frozen_string_literal: true
# rubocop:todo all

class Rating
  include Mongoid::Document
  field :value, type: Integer
  belongs_to :ratable, polymorphic: true
  has_many :comments
  validates_numericality_of :value, less_than: 100, allow_nil: true
  validates :ratable, associated: true
end
