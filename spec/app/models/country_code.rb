class CountryCode
  include Mongoid::Document
  field :code, :type => Integer
  key :code
  embedded_in :phone_number, :class_name => "Phone"
end
