class PlaneBuilder
  include Mongoid::Document

  field :location, type: Hash

  belongs_to :plane
end
