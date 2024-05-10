# frozen_string_literal: true
# rubocop:todo all

class LatLng
  attr_accessor :lat, :lng

  def self.demongoize(object)
    return if object.nil?

    LatLng.new(object[1], object[0])
  end

  def initialize(lat, lng)
    @lat, @lng = lat, lng
  end

  def mongoize
    [ lng, lat ]
  end

  def ==(other)
    lat == other.lat && lng == other.lng
  end
end
