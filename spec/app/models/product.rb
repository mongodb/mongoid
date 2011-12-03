class Product
  include Mongoid::Document
  field :description, :localize => true
  field :price, :type => Integer
  alias_attribute :cost, :price
end
