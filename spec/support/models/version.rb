# frozen_string_literal: true

class Version
  include Mongoid::Document
  field :number, type: :integer
  embedded_in :memorable, polymorphic: true
end
