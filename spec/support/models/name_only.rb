# frozen_string_literal: true

# Model with one field called name
class NameOnly
  include Mongoid::Document

  field :name, type: String
end
