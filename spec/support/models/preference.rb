# frozen_string_literal: true

class Preference
  include Mongoid::Document
  field :name, type: :string
  field :value, type: :string
  field :ranking, type: :integer
  has_and_belongs_to_many :people, validate: false
  validates_length_of :name, minimum: 2, allow_nil: true
  scope :posting, ->{ where(:value.in => [ "Posting" ]) }
end
