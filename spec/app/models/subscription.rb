class Subscription
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  has_many :packs, class_name: "ShippingPack"
end
