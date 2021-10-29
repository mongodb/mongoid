# frozen_string_literal: true

class Meat
  include Mongoid::Document
  has_and_belongs_to_many :sandwiches
end
