class Phone
  include Mongoid::Document
  field :number
  key :number
  belongs_to :person, :inverse_of => :phone_numbers
  has_one :country_code
end