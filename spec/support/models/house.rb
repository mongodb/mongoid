# frozen_string_literal: true
# rubocop:todo all

class House
  include Mongoid::Document
  field :name, type: String
  field :model, type: String
  default_scope ->{ asc(:name) }
end
