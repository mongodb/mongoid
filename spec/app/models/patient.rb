class Patient
  include Mongoid::Document
  field :title, type: "String"
  store_in collection: "inpatient"
  embeds_many :addresses, as: :addressable
  embeds_one :email
  embeds_one :name, as: :namable
  validates_presence_of :title, on: :create
end
