class Preference
  include Mongoid::Document
  field :name
  field :value
  references_many :people, :stored_as => :array, :inverse_of => :preferences
end
