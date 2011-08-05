class Drug
  include Mongoid::Document
  field :name, :type => String
  belongs_to :person
end
