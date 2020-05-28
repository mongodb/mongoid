# frozen_string_literal: true
# encoding: utf-8

class Translation
  include Mongoid::Document
  field :language
  embedded_in :name
end
