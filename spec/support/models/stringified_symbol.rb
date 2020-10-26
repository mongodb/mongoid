# frozen_string_literal: true
# encoding: utf-8

class StringifiedSymbol
  include Mongoid::Document
  store_in collection: "stringified_symbols", client: :other
  field :stringified_symbol, type: StringifiedSymbol
end
