# frozen_string_literal: true
# encoding: utf-8

class Order
  include Mongoid::Document
  field :status, type: Mongoid::StringifiedSymbol
end