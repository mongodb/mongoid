class Ghost
  include Mongoid::Document
  
  field :name, :type => String
  
  referenced_in :movie, :autosave => true
end