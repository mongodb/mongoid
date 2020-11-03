# frozen_string_literal: true
# encoding: utf-8

class Order
  include Mongoid::Document
  field :status, type: Mongoid::StringifiedSymbol

  # This is a dummy field that verifies the Mongoid::Fields::StringifiedSymbol
  # alias.
  field :saved_status, type: StringifiedSymbol
end
