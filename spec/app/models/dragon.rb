# frozen_string_literal: true

class Dragon
  include Mongoid::Document
  has_and_belongs_to_many :dungeons
end
