class Product
  include Mongoid::Document
  field :description, :type => String, :localize => true
end
