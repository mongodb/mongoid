class Movie
  include Mongoid::Document
  field :title, :type => String
  field :poster, :type => Image
  has_many :ratings, :as => :ratable, :dependent => :nullify
  has_many :comments
end
