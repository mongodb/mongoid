# frozen_string_literal: true
# rubocop:todo all

class RootCategory
  include Mongoid::Document
  embeds_many :categories
end
