# frozen_string_literal: true
# rubocop:todo all

class Driver
  include Mongoid::Document
  has_one :vehicle
  accepts_nested_attributes_for :vehicle
end

require "support/models/learner"
