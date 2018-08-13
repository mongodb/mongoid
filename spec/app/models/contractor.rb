# frozen_string_literal: true

class Contractor
  include Mongoid::Document
  embedded_in :building
  field :name, type: String
end
