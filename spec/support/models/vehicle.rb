# frozen_string_literal: true

class Vehicle
  include Mongoid::Document

  belongs_to :shipping_container
  belongs_to :driver

  embeds_many :crates
  embeds_many :seats, cascade_callbacks: true

  accepts_nested_attributes_for :driver
  accepts_nested_attributes_for :shipping_container
  accepts_nested_attributes_for :crates
end

require "support/models/car"
require "support/models/truck"
