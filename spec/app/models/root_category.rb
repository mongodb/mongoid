# frozen_string_literal: true

class RootCategory
  include Mongoid::Document
  embeds_many :categories
end
