# frozen_string_literal: true

class DeleteAllTag
  include Mongoid::Document

  field :state, type: String
end
