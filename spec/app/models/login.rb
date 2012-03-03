class Login
  include Mongoid::Document

  field :_id, type: String, default: ->{ username }

  field :username, type: String
  field :application_id, type: Integer
end
