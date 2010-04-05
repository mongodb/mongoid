class VetVisit
  include Mongoid::Document
  field :date, :type => Date
  embedded_in :pet, :inverse_of => :vet_visits
end
