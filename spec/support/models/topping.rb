# frozen_string_literal: true

class Topping
  include Mongoid::Document
  field :name, type: :string
  belongs_to :pizza
end
