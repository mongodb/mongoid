class Location
  include Mongoid::Document
  field :name
  embedded_in :address, :inverse_of => :locations
end
