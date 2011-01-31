class Location
  include Mongoid::Document
  field :name
  field :style
  embedded_in :address
end
