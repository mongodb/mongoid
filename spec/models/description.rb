class Description
  include Mongoid::Document

  field :details

  referenced_in :user
  referenced_in :updater, :class_name => 'User'
  
  accepts_nested_attributes_for :user, :allow_destroy => true, :save_parent => true
end
