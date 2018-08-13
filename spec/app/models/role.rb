# frozen_string_literal: true

class Role
  include Mongoid::Document
  field :name, type: String
  belongs_to :user
  belongs_to :post
  recursively_embeds_many
end
