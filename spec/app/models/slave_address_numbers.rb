# These models used for Github 263
class Slave
  include Mongoid::Document
  field :first_name
  field :last_name
  embeds_many :address_numbers
end

class AddressNumber
  include Mongoid::Document
  field :country_code, :type => Integer, :default => 1
  field :number
  embedded_in :slave
end
