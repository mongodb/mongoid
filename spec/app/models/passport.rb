class Passport
  include Mongoid::Document
  field :number, type: String
  embedded_in :person, autobuild: true
end
