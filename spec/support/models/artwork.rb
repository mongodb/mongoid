# frozen_string_literal: true
# rubocop:todo all

class Artwork
  include Mongoid::Document
  has_and_belongs_to_many :exhibitors
end
