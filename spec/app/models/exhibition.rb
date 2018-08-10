# frozen_string_literal: true

class Exhibition
  include Mongoid::Document
  has_many :exhibitors
end
