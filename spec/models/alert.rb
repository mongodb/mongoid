class Alert
  include Mongoid::Document
  field :message, :type => String
  referenced_in :account
end
