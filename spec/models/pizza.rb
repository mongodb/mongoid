class Pizza
  include Mongoid::Document
  field :name, :type => String
  has_one :topping, :autosave => true
  accepts_nested_attributes_for :topping
end
