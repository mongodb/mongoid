# frozen_string_literal: true
# encoding: utf-8

class Exhibition
  include Mongoid::Document
  has_many :exhibitors
end
