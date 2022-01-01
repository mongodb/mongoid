# frozen_string_literal: true

class Login
  include Mongoid::Document

  field :_id, type: :string, overwrite: true, default: ->{ username }

  field :username, type: :string
  field :application_id, type: :integer
end
