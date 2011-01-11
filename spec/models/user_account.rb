class UserAccount
  include Mongoid::Document
  field :username
  field :name
  field :email
  validates_uniqueness_of :username, :message => "is not unique"
  validates_uniqueness_of :email, :message => "is not unique", :case_sensitive => false
  validates_length_of :name, :minimum => 2, :allow_nil => true
  references_and_referenced_in_many :people
end
