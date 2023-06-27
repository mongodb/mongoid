# frozen_string_literal: true
# rubocop:todo all

class Node
  include Mongoid::Document
  has_many :servers
  accepts_nested_attributes_for :servers
end
