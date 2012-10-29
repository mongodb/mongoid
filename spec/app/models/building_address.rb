class BuildingAddress
  include Mongoid::Document
  embedded_in :building
  field :city, type: String
end
