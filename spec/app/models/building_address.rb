# frozen_string_literal: true
# encoding: utf-8

class BuildingAddress
  include Mongoid::Document
  field :city, type: String

  embedded_in :building
  validates_presence_of :city
end
