class Author
  include Mongoid::Document
  field :id, type: Integer
  field :author, type: Mongoid::Boolean
  field :name, type: String
end
