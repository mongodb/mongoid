class Account
  include Mongoid::Document
  referenced_in :creator, :class_name => "User", :foreign_key => :creator_id
  referenced_in :person
  field :number
  field :balance
  field :nickname
  
  attr_accessible :nickname
end
