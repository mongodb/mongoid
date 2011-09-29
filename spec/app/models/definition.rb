class Definition
  include Mongoid::Document
  field :description, :type => String
  field :part, :type => String
  field :regular, :type => Boolean
  embedded_in :word
end
