class PetOwner
  include Mongoid::Document
  field :title
  embeds_one :pet
  embeds_one :address, :as => :addressable
end
