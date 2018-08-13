# frozen_string_literal: true

class Series
  include Mongoid::Document
  has_many :books
end
