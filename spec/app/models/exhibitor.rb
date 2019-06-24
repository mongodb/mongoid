# frozen_string_literal: true
# encoding: utf-8

class Exhibitor
  include Mongoid::Document
  field :status, type: String
  belongs_to :exhibition
  has_and_belongs_to_many :artworks
end
