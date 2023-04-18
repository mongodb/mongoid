# frozen_string_literal: true
# rubocop:todo all

class Explosion
  include Mongoid::Document
  belongs_to :bomb
end
