class Animal
  include Mongoid::Document
  field :name
  key :name
  belongs_to :person, :inverse_of => :pet
end