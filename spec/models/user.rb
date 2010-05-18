class User
  include Mongoid::Document
  references_one :account, :foreign_key => :creator_id
  field :name
end
