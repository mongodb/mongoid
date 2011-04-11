class Movie
  include Mongoid::Document
  field :title, :type => String
  field :poster, :type => Image
  references_many :ratings, :as => :ratable, :dependent => :nullify
  references_many :comments
end
