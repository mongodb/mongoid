class Image
  include Mongoid::Fields::Serializable

  def initialize(name)
    @name = name
  end

  def deserialize(value)
    value.to_s
  end

  def serialize(value)
    value.to_s
  end
end
