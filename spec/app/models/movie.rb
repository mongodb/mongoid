class Movie
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :title, type: String
  field :poster, type: Image
  field :poster_thumb, type: Thumbnail
  has_many :ratings, as: :ratable, dependent: :nullify
  has_many :comments

  def global_set
    Set.new
  end
end
