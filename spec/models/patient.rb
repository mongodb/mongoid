class Email
  include Mongoid::Document
  field :address
  embedded_in :patient, :inverse_of => :email
end

class Patient
  include Mongoid::Document
  field :title
  store_in :inpatient
  embeds_many :addresses
  embeds_one :email
end
