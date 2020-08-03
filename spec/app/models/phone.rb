# frozen_string_literal: true
# encoding: utf-8

class Phone
  include Mongoid::Document

  field :_id, type: String, overwrite: true, default: ->{ number }

  field :number
  field :landline, type: Boolean
  embeds_one :country_code
  embedded_in :person
end
