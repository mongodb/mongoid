class PetOwner
  include Mongoid::Document
  field :title
  has_one :pet
  has_one :address
end