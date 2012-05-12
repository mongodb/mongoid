class Blog
  include Mongoid::Document
  has_many :posts, :validate => false
  default_scope includes(:posts)
end
