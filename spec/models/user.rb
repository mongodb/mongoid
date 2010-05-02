class User
  include Mongoid::Document
  has_one_related :account, :foreign_key => :creator_id
  field :name
end
