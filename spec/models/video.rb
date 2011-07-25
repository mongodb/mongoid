class Video
  include Mongoid::Document
  field :title
  embedded_in :person
  belongs_to :post
  belongs_to :game

  default_scope asc(:title)
end
