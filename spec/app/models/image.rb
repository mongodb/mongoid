class Image
  include Mongoid::Fields::Serializable

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def deserialize(value)
    self.class.new(value)
  end

  def serialize(value)
    value.name.to_s
  end

  def hash_is_hash
    {}.is_a?(Hash)
  end
end

class Thumbnail < Image
end
