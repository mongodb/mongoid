# frozen_string_literal: true

class Band
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :name, type: :string
  field :active, type: :boolean, default: true
  field :origin, type: :string
  field :genres, type: :array
  field :member_count, type: :integer
  field :mems, as: :members, type: :array
  field :likes, type: :integer
  field :views, type: :integer
  field :rating, type: :float
  field :upserted, type: :boolean, default: false
  field :created, type: :date_time
  field :sales, type: :big_decimal
  field :decimal, type: :decimal128
  field :y, as: :years, type: :integer
  field :founded, type: :date
  field :deleted, type: :boolean

  embeds_many :records, cascade_callbacks: true
  embeds_many :notes, as: :noteable, cascade_callbacks: true, validate: false
  embeds_many :labels
  embeds_one :label, cascade_callbacks: true

  scope :highly_rated, -> { gte(rating: 7) }

  has_many :artists
  has_many :same_name, class_name: 'Agent', inverse_of: :same_name

  after_upsert do |doc|
    doc.upserted = true
  end
end
