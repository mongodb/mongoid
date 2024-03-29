# frozen_string_literal: true
# rubocop:todo all

class Target
  include Mongoid::Document
  field :name, type: String
  embedded_in :targetable, polymorphic: true
end
