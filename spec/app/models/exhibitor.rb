class Exhibitor
  include Mongoid::Document
  field :status, type: String
  belongs_to :exhibition
  has_and_belongs_to_many :artworks
end
