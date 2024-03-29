# frozen_string_literal: true
# rubocop:todo all

class Login
  include Mongoid::Document

  field :_id, type: String, overwrite: true, default: ->{ username }

  field :username, type: String
  field :application_id, type: Integer
end
