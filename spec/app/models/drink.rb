class Drink
  include Mongoid::Document
  has_one :recipe
  field :name
end
