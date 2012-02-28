class Vehicle
  include Mongoid::Document
  belongs_to :shipping_container
  belongs_to :driver

  accepts_nested_attributes_for :driver
  accepts_nested_attributes_for :shipping_container
end

require "app/models/car"
require "app/models/truck"
