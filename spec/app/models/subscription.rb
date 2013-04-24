class Subscription
  include Mongoid::Document
  has_many :packs, class_name: "ShippingPack"
end
