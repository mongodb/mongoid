class Network
  include Mongoid::Document
  field :name
  has_many :hosts
end
