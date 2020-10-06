# frozen_string_literal: true
# encoding: utf-8

class Deed
  include Mongoid::Document
  field :title, type: String
  embedded_in :owner
end
