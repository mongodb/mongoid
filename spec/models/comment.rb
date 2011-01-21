class Comment
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  field :title, :type => String
  field :text, :type => String
  key :text, :type => String

  referenced_in :movie
  referenced_in :rating
  validates :title, :presence => true
  validates :movie, :rating, :associated => true
end
