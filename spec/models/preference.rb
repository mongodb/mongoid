class Preference
  include Mongoid::Document
  field :name
  field :value
  references_many :people, :stored_as => :array, :inverse_of => :preferences
  validates_length_of :name, :minimum => 2, :allow_nil => true
end
