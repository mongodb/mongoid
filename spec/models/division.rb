class Division
  include Mongoid::Document
  field :name, :type => String
  embedded_in :league
end
