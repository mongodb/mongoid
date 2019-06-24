# frozen_string_literal: true
# encoding: utf-8

class Simple
  include Mongoid::Document
  field :name, type: String
  scope :nothing, -> { none }
end
