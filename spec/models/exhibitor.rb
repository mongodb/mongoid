class Exhibitor
  include Mongoid::Document
  belongs_to :exhibition
  has_and_belongs_to_many :artworks
end
