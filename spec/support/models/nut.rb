# frozen_string_literal: true

class Nut
  include Mongoid::Document

  belongs_to :hole
end
