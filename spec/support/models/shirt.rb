# frozen_string_literal: true
# encoding: utf-8

class Shirt
  include Mongoid::Document

  field :color, type: String

  unalias_attribute :id

  field :id, type: String
end
