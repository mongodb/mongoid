class Comment
  include Mongoid::Document

  field :title, type: String
  field :text, type: String

  belongs_to :account
  belongs_to :movie
  belongs_to :rating
  belongs_to :wiki_page

  belongs_to :commentable, polymorphic: true

  validates :title, presence: true
  validates :movie, :rating, associated: true
end
