class Favorite
  include Mongoid::Document

  field :title
  
  embedded_in :person, :inverse_of => :favorites
end