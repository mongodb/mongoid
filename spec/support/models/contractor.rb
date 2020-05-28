# frozen_string_literal: true
# encoding: utf-8

class Contractor
  include Mongoid::Document
  embedded_in :building
  field :name, type: String
end
