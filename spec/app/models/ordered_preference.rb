# frozen_string_literal: true
# encoding: utf-8

class OrderedPreference
  include Mongoid::Document
  field :name, type: String
  field :value, type: String
  has_and_belongs_to_many :people, validate: false
end
