# frozen_string_literal: true
# encoding: utf-8

class Location
  include Mongoid::Document
  field :name
  field :info, type: Hash
  field :occupants, type: Array
  field :number, type: Integer
  embedded_in :address
end
