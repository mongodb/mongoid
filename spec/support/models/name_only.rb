# frozen_string_literal: true
# encoding: utf-8

# Model with one field called name
class NameOnly
  include Mongoid::Document

  field :name, type: String
end
