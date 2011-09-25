class Comment
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  field :title, :type => String
  field :text, :type => String
  key :text, :type => String

  belongs_to :account
  belongs_to :movie
  belongs_to :rating
  validates :title, :presence => true
  validates :movie, :rating, :associated => true
end
