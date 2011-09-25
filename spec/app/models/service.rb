class Service
  include Mongoid::Document
  field :sid
  embedded_in :person
  validates_numericality_of :sid
end
