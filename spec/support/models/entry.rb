# frozen_string_literal: true
# rubocop:todo all

class Entry
  include Mongoid::Document
  field :title, type: String
  field :body, type: String
  recursively_embeds_many
end
