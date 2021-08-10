# frozen_string_literal: true
# encoding: utf-8

class Agency
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::Attributes::Dynamic
  has_many :agents, validate: false
end
