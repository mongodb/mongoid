# frozen_string_literal: true
# rubocop:todo all

class Language
  include Mongoid::Document
  field :name, type: String
  embedded_in :translatable, polymorphic: true
end
