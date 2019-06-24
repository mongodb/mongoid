# frozen_string_literal: true
# encoding: utf-8

class Template
  include Mongoid::Document
  field :active, type: Mongoid::Boolean, default: false
  validates :active, presence: true
end
