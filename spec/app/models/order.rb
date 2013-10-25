class Order
  include Mongoid::Document
  field :customer_name, default: -> { customer.name }
  embedded_in :customer
end
