class UserAccount
  include Mongoid::Document
  field :username
  validates_uniqueness_of :username, :message => "is not unique"

  referenced_in :person, :inverse_of => :user_accounts
end
