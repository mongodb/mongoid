# frozen_string_literal: true
# encoding: utf-8

class StringifiedSymbol
  include Mongoid::Document
  field :stringified_symbol, type: StringifiedSymbol
end
