class Patient
  include Mongoid::Document
  field :title
  store_in :inpatient
end
