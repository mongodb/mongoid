class Dog
  include Mongoid::Document
  field :name, type: String
  has_and_belongs_to_many :breeds
  default_scope asc(:name)
end
