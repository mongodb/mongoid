# frozen_string_literal: true
# rubocop:todo all

class Dragon
  include Mongoid::Document
  has_and_belongs_to_many :dungeons
end
