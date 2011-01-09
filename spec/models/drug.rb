class Drug
  include Mongoid::Document
  field :name, :type => String
  referenced_in :person
end
