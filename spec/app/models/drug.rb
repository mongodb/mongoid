class Drug
  include Mongoid::Document
  field :name, type: String
  field :generic, type: Boolean
  belongs_to :person
end
