# frozen_string_literal: true

class Definition
  include Mongoid::Document
  field :description, type: :string
  field :p, as: :part, type: :string
  field :regular, type: :boolean
  field :syn, as: :synonyms, localize: true, type: :string
  field :active, type: :boolean, localize: true, default: true
  embedded_in :word
end
