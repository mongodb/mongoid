class Product
  include Mongoid::Document
  field :description, :localize => true
  field :name, :localize => true, :default => "no translation"
  field :price, :type => Integer
  field :brand_name
  alias_attribute :cost, :price

  validates :name, :presence => true
end
