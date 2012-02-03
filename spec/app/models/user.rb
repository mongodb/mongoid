class User
  include Mongoid::Document

  field :name
  field :last_login, type: DateTime
  field :account_expires, type: Date

  has_one :account, foreign_key: :creator_id, validate: false
  has_many :posts, foreign_key: :author_id, validate: false
  has_many :descriptions

  has_and_belongs_to_many :followed_shops, inverse_of: :followers, class_name: "Shop"
  has_and_belongs_to_many :businesses, class_name: "Business", validate: false
  has_one :shop

  accepts_nested_attributes_for :posts
  index name: 1
end
