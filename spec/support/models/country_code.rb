# frozen_string_literal: true
# encoding: utf-8

class CountryCode
  include Mongoid::Document

  field :_id, type: Integer, overwrite: true, default: ->{ code }

  field :code, type: Integer
  embedded_in :phone_number, class_name: "Phone"
end
