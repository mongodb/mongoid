# frozen_string_literal: true

class Video
  include Mongoid::Document
  field :title, type: :string
  field :year, type: :integer
  field :release_dates, type: :set
  field :genres, type: :array

  embedded_in :person
  belongs_to :post
  belongs_to :game

  default_scope ->{ asc(:title) }
end
