class Account
  include Mongoid::Document
  field :number, :type => String
  field :balance, :type => String
  field :nickname, :type => String
  field :name, :type => String
  key :name

  embeds_many :memberships
  belongs_to :creator, :class_name => "User", :foreign_key => :creator_id
  belongs_to :person
  has_many :alerts
  has_and_belongs_to_many :agents
  has_one :comment, :validate => false

  attr_accessible :nickname, :name

  validates_presence_of :name
  validates_length_of :name, :maximum => 10, :on => :create
end
