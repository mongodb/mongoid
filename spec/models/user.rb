class User
  include Mongoid::Document
  references_one :account, :foreign_key => :creator_id
  references_many :posts, :foreign_key => :author_id
  field :name

  references_many :descriptions
end
