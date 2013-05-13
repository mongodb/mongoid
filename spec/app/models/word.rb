class Word
  include Mongoid::Document
  field :name, type: String
  field :origin, type: String

  belongs_to :dictionary

  embeds_many :definitions, validate: false
  embeds_many :word_origins, validate: false
  embeds_one :pronunciation, validate: false

  accepts_nested_attributes_for :definitions, allow_destroy: true

  index({ name: "text" }, default_language: "english")
end
