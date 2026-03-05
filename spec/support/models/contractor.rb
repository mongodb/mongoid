# frozen_string_literal: true
# rubocop:todo all

class Contractor
  include Mongoid::Document
  embedded_in :building
  field :name, type: String
end
