# frozen_string_literal: true

class ContextableItem
  include Mongoid::Document
  field :title
  validates :title, presence: true, on: :in_context
end
