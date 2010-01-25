class Location
  include Mongoid::Document
  field :name
  belongs_to :address, :inverse_of => :locations
end