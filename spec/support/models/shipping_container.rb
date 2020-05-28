# frozen_string_literal: true
# encoding: utf-8

class ShippingContainer
  include Mongoid::Document
  has_many :vehicles
  accepts_nested_attributes_for :vehicles
end
