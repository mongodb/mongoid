class VetVisit
  include Mongoid::Document
  field :date, :type => Date
  belongs_to :pet, :inverse_of => :vet_visits
end