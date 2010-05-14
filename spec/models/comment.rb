class Comment
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps
  field :title

  field :text
  key :text
  validates_presence_of :text
end
