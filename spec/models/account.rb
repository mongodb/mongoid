class Account
  include Mongoid::Document
  field :number, :type => String
  field :balance, :type => String
  field :nickname, :type => String
  field :name, :type => String
  key :name

  embeds_many :memberships
  referenced_in :creator, :class_name => "User", :foreign_key => :creator_id
  referenced_in :person
  references_many :alerts
  references_and_referenced_in_many :agents

  attr_accessible :nickname, :name

  validates_presence_of :name
  validates_length_of :name, :maximum => 10, :on => :create
end
