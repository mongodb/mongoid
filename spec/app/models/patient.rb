class Email
  include Mongoid::Document
  field :address
  validates_uniqueness_of :address
  embedded_in :patient
end

class Patient
  include Mongoid::Document
  field :title, :type => "String"
  store_in :inpatient
  embeds_many :addresses, :as => :addressable
  embeds_one :email
  embeds_one :name, :as => :namable
  validates_presence_of :title, :on => :create
end
