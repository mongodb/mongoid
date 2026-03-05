# frozen_string_literal: true
# rubocop:todo all

class PostGenre
  include Mongoid::Document
  field :posts_count, type: Integer, default: 0

  has_many :posts, inverse_of: :genre
end
