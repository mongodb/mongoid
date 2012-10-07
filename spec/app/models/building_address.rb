class BuildingAddress
  include Mongoid::Document
  attr_accessible
  attr_accessible :city, as: :admin
  embedded_in :building
  field :city, type: String
end
