class Favorite
  include Mongoid::Document

  field :title
  validates_uniqueness_of :title

  embedded_in :person, :inverse_of => :favorites
end
