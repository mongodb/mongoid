# frozen_string_literal: true

class Owner
  include Mongoid::Document
  field :name
  has_many :events
  embeds_many :birthdays
  embeds_many :deeds
  embeds_one :scribe
end
