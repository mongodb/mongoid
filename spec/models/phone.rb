class Phone
  include Mongoid::Document
  field :number
  key :number
  embeds_one :country_code
  embedded_in :person, :inverse_of => :phone_numbers
end
