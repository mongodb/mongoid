# frozen_string_literal: true
# rubocop:todo all

class Category
  include Mongoid::Document
  embedded_in :root_category
  embedded_in :category
  embeds_many :categories

  field :name
end
