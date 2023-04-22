# frozen_string_literal: true
# rubocop:todo all

class Dungeon
  include Mongoid::Document
  has_and_belongs_to_many :dragons
end
