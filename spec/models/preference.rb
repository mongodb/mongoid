class Preference
  include Mongoid::Document
  field :name
  field :value
  references_and_referenced_in_many :people
  validates_length_of :name, :minimum => 2, :allow_nil => true
end
