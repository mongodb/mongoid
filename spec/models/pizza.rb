class Pizza
  include Mongoid::Document
  has_one :topping
  accepts_nested_attributes_for :topping
end
