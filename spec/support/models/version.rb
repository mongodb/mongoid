# frozen_string_literal: true
# encoding: utf-8

class Version
  include Mongoid::Document
  field :number, type: Integer
  embedded_in :memorable, polymorphic: true
end
