# frozen_string_literal: true

class Phone
  include Mongoid::Document

  field :_id, type: :string, overwrite: true, default: ->{ number }
  field :number
  field :ext, as: :extension
  field :landline, type: :boolean

  embeds_one :country_code
  embedded_in :person
end
