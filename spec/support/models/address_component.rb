# frozen_string_literal: true
# rubocop:todo all

class AddressComponent
  include Mongoid::Document
  field :street, type: String
  embedded_in :person
end
