class Actor
  include Mongoid::Document
  field :name
  has_and_belongs_to_many :tags
end
