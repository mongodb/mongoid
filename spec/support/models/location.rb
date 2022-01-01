# frozen_string_literal: true

class Location
  include Mongoid::Document
  field :name
  field :info, type: :hash
  field :occupants, type: :array
  field :number, type: :integer
  embedded_in :address
end
