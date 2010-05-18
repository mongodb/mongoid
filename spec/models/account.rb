class Account
  include Mongoid::Document
  referenced_in :creator, :class_name => "User", :foreign_key => :creator_id
  field :number
end
