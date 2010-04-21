class Account
  include Mongoid::Document
  belongs_to_related :creator, :class_name => "User", :foreign_key => :creator_id
  field :number
end
