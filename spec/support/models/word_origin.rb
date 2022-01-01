# frozen_string_literal: true

class WordOrigin
  include Mongoid::Document

  field :_id, type: :integer, overwrite: true, default: ->{ origin_id }

  field :origin_id, type: :integer
  field :country, type: :string
  field :city, type: :string

  embedded_in :word
end
