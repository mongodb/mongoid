class Product
  include Mongoid::Document
  field :description, :localize => true
  field :name, :localize => true, :default => "no translation"
  field :price, :type => Integer
  alias_attribute :cost, :price
end
