# frozen_string_literal: true
# encoding: utf-8

class Kaleidoscope
  include Mongoid::Document
  field :active, type: Mongoid::Boolean, default: true

  scope :activated, -> { where(active: true) }
end
