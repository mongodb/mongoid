class ShippingContainer
  include Mongoid::Document
  has_many :vehicles
  accepts_nested_attributes_for :vehicles
end
