# frozen_string_literal: true
# encoding: utf-8

class Series
  include Mongoid::Document
  has_many :books
end
