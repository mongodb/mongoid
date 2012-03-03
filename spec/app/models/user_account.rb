class UserAccount
  include Mongoid::Document
  field :username, type: String
  field :name, type: String
  field :email, type: String
  validates_uniqueness_of :username, message: "is not unique"
  validates_uniqueness_of :email, message: "is not unique", case_sensitive: false
  validates_length_of :name, minimum: 2, allow_nil: true
  has_and_belongs_to_many :people
end
