class Description
  include Mongoid::Document

  field :details

  belongs_to_related :user
  belongs_to_related :updater, :class_name => 'User'
end
