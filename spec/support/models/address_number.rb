# frozen_string_literal: true
# rubocop:todo all

class AddressNumber
  include Mongoid::Document
  field :country_code, type: Integer, default: 1
  field :number
  embedded_in :slave
end
