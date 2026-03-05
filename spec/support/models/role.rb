# frozen_string_literal: true
# rubocop:todo all

class Role
  include Mongoid::Document
  field :name, type: String
  belongs_to :user
  belongs_to :post
  recursively_embeds_many
end
