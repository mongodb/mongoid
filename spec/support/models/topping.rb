# frozen_string_literal: true
# rubocop:todo all

class Topping
  include Mongoid::Document
  field :name, type: String
  belongs_to :pizza
end
