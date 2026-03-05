# frozen_string_literal: true
# rubocop:todo all

class Nut
  include Mongoid::Document

  belongs_to :hole
end
