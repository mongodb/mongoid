class Artist
  include Mongoid::Document
  field :name, :type => String
  has_many :albums, :dependent => :destroy
end
