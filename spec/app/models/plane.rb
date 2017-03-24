class Plane
  include Mongoid::Document

  has_one :plane_builder, autobuild: true
end
