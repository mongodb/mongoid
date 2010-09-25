class UserAccount
  include Mongoid::Document
  field :username
  field :email
  validates_uniqueness_of :username, :message => "is not unique"
  validates_uniqueness_of :email, :message => "is not unique", :case_sensitive => false

  referenced_in :person, :inverse_of => :user_accounts
end
