class Contractor
  include Mongoid::Document
  attr_accessible
  attr_accessible :name, as: :admin
  embedded_in :building
  field :name, type: String
end
