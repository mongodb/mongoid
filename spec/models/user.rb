class User
  include Mongoid::Document

  field :name
  field :last_login, :type => DateTime
  field :account_expires, :type => Date

  has_one :account, :foreign_key => :creator_id
  has_many :posts, :foreign_key => :author_id
  has_many :descriptions
end
