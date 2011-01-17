class Membership
  include Mongoid::Document
  embedded_in :account
end
