# frozen_string_literal: true
# encoding: utf-8

class House
  include Mongoid::Document
  field :name, type: String
  field :model, type: String
  default_scope ->{ asc(:name) }
end
