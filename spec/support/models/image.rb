# frozen_string_literal: true

class Image
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def self.demongoize(value)
    Image.new(value)
  end

  def mongoize
    name
  end

  def hash_is_hash
    {}.is_a?(Hash)
  end
end

class Thumbnail < Image
end
