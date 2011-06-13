class Pizza
  include Mongoid::Document
  has_one :crust
  has_many :toppings
  accepts_nested_attributes_for :crust, :toppings
end
class Crust
  include Mongoid::Document
  field :type
  belongs_to :pizza
end
class Topping
  include Mongoid::Document
  field :name
  belongs_to :pizza
end
