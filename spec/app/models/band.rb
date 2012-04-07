class Band
  include Mongoid::Document
  field :name, type: String
  field :active, type: Boolean, default: true
  field :origin, type: String
  field :genres, type: Array
  field :member_count, type: Integer
  field :members, type: Array
  field :likes, type: Integer
  field :views, type: Integer

  embeds_many :records, cascade_callbacks: true
  embeds_many :notes, as: :noteable, cascade_callbacks: true, validate: false
  embeds_one :label, cascade_callbacks: true
end
