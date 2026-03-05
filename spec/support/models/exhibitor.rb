# frozen_string_literal: true
# rubocop:todo all

class Exhibitor
  include Mongoid::Document
  field :status, type: String
  belongs_to :exhibition
  has_and_belongs_to_many :artworks
end
