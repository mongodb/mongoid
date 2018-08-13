# frozen_string_literal: true

class FireHydrant
  include Mongoid::Document
  field :location, type: String
  has_and_belongs_to_many :dogs, primary_key: :name
  has_and_belongs_to_many :cats, primary_key: :name
end
