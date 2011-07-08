class Image
  include Mongoid::Fields::Serializable

  def deserialize(value)
    value.to_s
  end

  def serialize(value)
    value.to_s
  end
end
