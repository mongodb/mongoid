# frozen_string_literal: true
# encoding: utf-8

class AddressComponent
  include Mongoid::Document
  field :street, type: String
  embedded_in :person
end
