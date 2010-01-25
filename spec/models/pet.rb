class Pet
  include Mongoid::Document
  field :name
  field :weight, :type => Float, :default => 0.0
  has_many :vet_visits
  belongs_to :pet_owner, :inverse_of => :pet
end