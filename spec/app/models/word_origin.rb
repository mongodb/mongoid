# frozen_string_literal: true

class WordOrigin
  include Mongoid::Document

  field :_id, type: Integer, overwrite: true, default: ->{ origin_id }

  field :origin_id, type: Integer
  field :country, type: String
  field :city, type: String

  embedded_in :word
end
