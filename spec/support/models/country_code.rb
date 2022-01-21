# frozen_string_literal: true

class CountryCode
  include Mongoid::Document

  field :_id, type: Integer, overwrite: true, default: ->{ code }

  field :code, type: Integer
  field :iso, as: :iso_alpha2_code

  embedded_in :phone_number, class_name: "Phone"
end
