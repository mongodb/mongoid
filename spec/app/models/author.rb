class Author
  include Mongoid::Document
  field :name, type: String

  belongs_to :paranoid_post
end
