# frozen_string_literal: true
# encoding: utf-8

class Driver
  include Mongoid::Document
  has_one :vehicle
  accepts_nested_attributes_for :vehicle
end

require "app/models/learner"
