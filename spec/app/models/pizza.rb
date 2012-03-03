class Pizza
  include Mongoid::Document
  field :name, type: String
  has_one :topping, autosave: true
  validates_presence_of :topping
  accepts_nested_attributes_for :topping
end
