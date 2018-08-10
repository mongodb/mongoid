# frozen_string_literal: true

class Definition
  include Mongoid::Document
  field :description, type: String
  field :p, as: :part, type: String
  field :regular, type: Mongoid::Boolean
  field :syn, as: :synonyms, localize: true, type: String
  field :active, type: Mongoid::Boolean, localize: true, default: true
  embedded_in :word
end
