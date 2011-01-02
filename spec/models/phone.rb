class Phone
  include Mongoid::Document
  field :number
  key :number
  embeds_one :country_code
  embedded_in :person
end
