class Service
  include Mongoid::Document
  field :sid
  embedded_in :person
  belongs_to :target, :class_name => "User"
  validates_numericality_of :sid
end
