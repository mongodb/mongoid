class Alert
  include Mongoid::Document
  field :message, type: String
  belongs_to :account
end
