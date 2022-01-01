# frozen_string_literal: true

class Author
  include Mongoid::Document
  field :id, type: :integer
  field :author, type: :boolean
  field :name, type: :string
end
