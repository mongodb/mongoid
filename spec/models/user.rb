class User
  include Mongoid::Document

  field :name

  references_one :account, :foreign_key => :creator_id
  references_many :posts, :foreign_key => :author_id
  references_many :descriptions
end
