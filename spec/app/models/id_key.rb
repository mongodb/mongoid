# frozen_string_literal: true
# encoding: utf-8

class IdKey
  include Mongoid::Document
  field :key
  alias_method :id,  :key
  alias_method :id=, :key=
end
