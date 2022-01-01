# frozen_string_literal: true

class Entry
  include Mongoid::Document
  field :title, type: :string
  field :body, type: :string
  recursively_embeds_many
end
