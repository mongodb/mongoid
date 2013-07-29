class Definition
  include Mongoid::Document
  field :description, type: String
  field :p, as: :part, type: String
  field :regular, type: Boolean
  field :syn, as: :synonyms, localize: true, type: String
  embedded_in :word
end
