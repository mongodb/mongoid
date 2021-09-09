# frozen_string_literal: true

class Pronunciation
  include Mongoid::Document
  field :sound, type: String
  embedded_in :word
end
