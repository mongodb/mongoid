# frozen_string_literal: true

class Explosion
  include Mongoid::Document
  belongs_to :bomb
end
