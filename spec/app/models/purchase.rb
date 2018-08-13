# frozen_string_literal: true

class Purchase
  include Mongoid::Document
  embeds_many :line_items
end
