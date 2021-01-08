# frozen_string_literal: true
# encoding: utf-8

class CustomerAddress
  include Mongoid::Document

  field :street, type: String
  field :city, type: String
  field :state, type: String

  embedded_in :addressable, polymorphic: true
end
