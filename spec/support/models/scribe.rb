# frozen_string_literal: true
# encoding: utf-8

class Scribe
  include Mongoid::Document
  field :name, type: String
  embedded_in :owner
end
