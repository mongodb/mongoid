class Service
  include Mongoid::Document

  embedded_in :person

  field :sid

  validates_numericality_of :sid
end
