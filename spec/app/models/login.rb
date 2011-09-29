class Login
  include Mongoid::Document
  field :username, :type => String
  field :application_id, :type => Integer
  key :username
end
