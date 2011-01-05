class Email
  include Mongoid::Document
  field :address
  validates_uniqueness_of :address
  embedded_in :patient
end

class Patient
  include Mongoid::Document
  field :title
  store_in :inpatient
  embeds_many :addresses, :as => :addressable
  embeds_one :email
  validates_presence_of :title, :on => :create
end
