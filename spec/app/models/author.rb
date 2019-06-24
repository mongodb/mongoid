# frozen_string_literal: true
# encoding: utf-8

class Author
  include Mongoid::Document
  field :id, type: Integer
  field :author, type: Mongoid::Boolean
  field :name, type: String
end
