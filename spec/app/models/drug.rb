class Drug
  include Mongoid::Document
  field :name, type: String
  field :generic, type: Boolean
  belongs_to :person, counter_cache: true
  attr_accessible :name, as: [ :default, :admin ]
  attr_accessible :person_id
end
