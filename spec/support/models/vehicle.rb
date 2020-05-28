# frozen_string_literal: true
# encoding: utf-8

class Vehicle
  include Mongoid::Document
  belongs_to :shipping_container
  belongs_to :driver

  accepts_nested_attributes_for :driver
  accepts_nested_attributes_for :shipping_container
end

require "support/models/car"
require "support/models/truck"
