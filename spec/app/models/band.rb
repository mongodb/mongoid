class Band
  include Mongoid::Document
  field :name, type: String
  field :active, type: Boolean, default: true
  field :origin, type: String

  embeds_many :records, cascade_callbacks: true
  embeds_many :notes, as: :noteable, cascade_callbacks: true, validate: false
  embeds_one :label, cascade_callbacks: true
end
