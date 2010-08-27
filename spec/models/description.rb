class Description
  include Mongoid::Document

  field :details

  referenced_in :user
  referenced_in :updater, :class_name => 'User'
end
