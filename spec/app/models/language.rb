# frozen_string_literal: true
# encoding: utf-8

class Language
  include Mongoid::Document
  field :name, type: String
  embedded_in :translatable, polymorphic: true
end
