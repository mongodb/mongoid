# frozen_string_literal: true
# rubocop:todo all

class Author
  include Mongoid::Document
  field :id, type: Integer
  field :author, type: Mongoid::Boolean
  field :name, type: String
end
