class Patient
  include Mongoid::Document
  field :title
  store_in :inpatient
  embed_many :addresses
end
