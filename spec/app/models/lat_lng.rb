class LatLng
  include Mongoid::Fields::Serializable

  def deserialize(object)
    { :lat => object[1], :lng => object[0] }.with_indifferent_access
  end

  def serialize(object)
    latlng = object.with_indifferent_access
    [ latlng[:lng], latlng[:lat] ]
  end
end
