# frozen_string_literal: true

class LatLng
  attr_accessor :lat, :lng

  def self.demongoize(object)
    LatLng.new(object[1], object[0])
  end

  def initialize(lat, lng)
    @lat, @lng = lat, lng
  end

  def mongoize
    [ lng, lat ]
  end
end
