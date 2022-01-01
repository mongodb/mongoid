# frozen_string_literal: true

class Church
  include Mongoid::Document
  has_many :acolytes, validate: false
  field :location, type: :hash
  field :name, type: :string
end
