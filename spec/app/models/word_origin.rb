class WordOrigin
  include Mongoid::Document
  field :origin_id, :type => Integer
  field :country, :type => String
  field :city, :type => String

  key :origin_id

  embedded_in :word
end
