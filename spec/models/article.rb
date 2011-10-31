class Article
  include Mongoid::Document
  include Mongoid::Timestamps
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :preferences, :inverse_of => nil, :validate => false
end
