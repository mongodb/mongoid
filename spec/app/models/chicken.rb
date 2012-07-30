class Chicken
  include Mongoid::Document

  field :thigh, type: Boolean, default: false
  field :leg, type: Boolean, default: false
  field :breast, type: Boolean, default: false

  attr_accessible :thigh, :leg, :breast
end
