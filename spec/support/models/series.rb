# frozen_string_literal: true
# encoding: utf-8

class Series
  include Mongoid::Document
  # Must not have dependent: :destroy
  has_many :books
end
