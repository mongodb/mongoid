class Article
  include Mongoid::Document

  field :title, type: String
  field :is_rss, type: Boolean, default: false
  field :user_login, type: String

  attr_accessible :title, as: [:default, :parser]
  attr_accessible :is_rss, as: :parser
  attr_accessible :user_login
  has_and_belongs_to_many :tags, validate: false
  has_and_belongs_to_many :preferences, inverse_of: nil, validate: false
end
