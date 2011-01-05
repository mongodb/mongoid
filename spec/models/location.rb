class Location
  include Mongoid::Document
  field :name
  embedded_in :address
end
