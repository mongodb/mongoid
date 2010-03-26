class Pet
  include Mongoid::Document
  field :name
  field :weight, :type => Float, :default => 0.0
  embeds_many :vet_visits
  embedded_in :pet_owner, :inverse_of => :pet
end
