class Band
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :name, type: String
  field :active, type: Mongoid::Boolean, default: true
  field :origin, type: String
  field :genres, type: Array
  field :member_count, type: Integer
  field :mems, as: :members, type: Array
  field :likes, type: Integer
  field :views, type: Integer
  field :rating, type: Float
  field :upserted, type: Mongoid::Boolean, default: false
  field :created, type: DateTime
  field :sales, type: BigDecimal
  field :y, as: :years, type: Integer
  field :founded, type: Date
  field :deleted, type: Boolean

  embeds_many :records, cascade_callbacks: true
  embeds_many :notes, as: :noteable, cascade_callbacks: true, validate: false
  embeds_one :label, cascade_callbacks: true

  after_upsert do |doc|
    doc.upserted = true
  end
end
