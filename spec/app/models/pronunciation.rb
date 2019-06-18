# frozen_string_literal: true
# encoding: utf-8

class Pronunciation
  include Mongoid::Document
  field :sound, type: String
  embedded_in :word
end
