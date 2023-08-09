# frozen_string_literal: true
# rubocop:todo all

class Washer
  include Mongoid::Document

  belongs_to :hole
end
