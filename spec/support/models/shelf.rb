# frozen_string_literal: true
# rubocop:todo all

class Shelf
  include Mongoid::Document
  field :level, type: Integer
  recursively_embeds_one
end
