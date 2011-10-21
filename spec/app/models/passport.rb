class Passport
  include Mongoid::Document
  field :number
  embedded_in :person
end
