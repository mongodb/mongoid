# frozen_string_literal: true

class Language
  include Mongoid::Document
  field :name, type: :string
  embedded_in :translatable, polymorphic: true
end
