class Video
  include Mongoid::Document
  field :title, type: String
  field :year, type: Integer
  field :release_dates, type: Set
  field :genres, type: Array

  embedded_in :person
  belongs_to :post
  belongs_to :game

  default_scope ->{ asc(:title) }
end
