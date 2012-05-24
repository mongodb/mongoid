class Actor
  include Mongoid::Document
  field :name
  has_and_belongs_to_many :tags
  embeds_many :things, validate: false, cascade_callbacks: true
  accepts_nested_attributes_for :things, allow_destroy: true
end

require "app/models/actress"
