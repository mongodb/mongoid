# frozen_string_literal: true

class Odd
  include Mongoid::Document
  field :name

  belongs_to :parent, class_name: 'Even', inverse_of: :odds
  has_many :evens, inverse_of: :parent
end
