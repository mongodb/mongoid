class Artwork
  include Mongoid::Document
  has_and_belongs_to_many :exhibitors
end
