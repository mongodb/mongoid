# frozen_string_literal: true
# rubocop:todo all

class Meat
  include Mongoid::Document
  has_and_belongs_to_many :sandwiches
end
