class Bar
  include Mongoid::Document
  field :name, type: String
  field :location, type: Array
  field :lat_lng, type: LatLng

  has_one :rating, as: :ratable
  index location: "2d"
end
