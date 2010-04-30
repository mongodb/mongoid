class Login
  include Mongoid::Document
  field :username
  key :username
  validates_uniqueness_of :username
end
