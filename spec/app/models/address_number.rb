# frozen_string_literal: true
# encoding: utf-8

class AddressNumber
  include Mongoid::Document
  field :country_code, type: Integer, default: 1
  field :number
  embedded_in :slave
end
