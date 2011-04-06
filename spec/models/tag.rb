class Tag
  include Mongoid::Document
  field :text, :type => String
  references_and_referenced_in_many :posts
  references_and_referenced_in_many :related, :class_name => "Tag"
end
