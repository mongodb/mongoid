# frozen_string_literal: true
# rubocop:todo all

class Exhibition
  include Mongoid::Document
  has_many :exhibitors
end
