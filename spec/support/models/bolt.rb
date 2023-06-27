# frozen_string_literal: true
# rubocop:todo all

class Bolt
  include Mongoid::Document

  belongs_to :hole
end
