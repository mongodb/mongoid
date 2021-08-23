# frozen_string_literal: true

class Dictionary
  include Mongoid::Document
  field :name, type: String
  field :publisher, type: String
  field :year, type: Integer

  # This field must be a Time
  field :published, type: Time

  # This field must be a Date
  field :submitted_on, type: Date

  field :description, type: String, localize: true
  field :l, type: String, as: :language
  has_many :words, validate: false
end
