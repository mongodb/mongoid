class PetOwner
  include Mongoid::Document
  field :title
  embed_one :pet
  embed_one :address
end
