# frozen_string_literal: true

class Author
  include Mongoid::Document
  field :id, type: Integer
  field :author, type: Mongoid::Boolean
  field :name, type: String
end
