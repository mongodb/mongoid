class Description
  include Mongoid::Document

  field :details

  referenced_in :user
  referenced_in :updater, :class_name => 'User'

  validates :user, :associated => true
  validates :details, :presence => true
end
