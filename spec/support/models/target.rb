# frozen_string_literal: true

class Target
  include Mongoid::Document
  field :name, type: :string
  embedded_in :targetable, polymorphic: true
end
