class Favorite
  include Mongoid::Document

  field :title
  validates_uniqueness_of :title, :case_sensitive => false

  embedded_in :person, :inverse_of => :favorites
end
