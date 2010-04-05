class Animal
  include Mongoid::Document
  field :name
  key :name
  embedded_in :person, :inverse_of => :pet
end
