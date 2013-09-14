class Customer
  include Mongoid::Document
  field :name
  embeds_one :order
end
