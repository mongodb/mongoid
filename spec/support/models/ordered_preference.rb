# frozen_string_literal: true

class OrderedPreference
  include Mongoid::Document
  field :name, type: :string
  field :value, type: :string
  has_and_belongs_to_many :people, validate: false
end
