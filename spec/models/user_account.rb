class UserAccount
  include Mongoid::Document
  field :username
  validates_uniqueness_of :username, :message => "is not unique"
  references_and_referenced_in_many :people, :as => :accountables
end
