class Location
  include Mongoid::Document
  field :name
  field :info, :type => Hash
  field :occupants, :type => Array
  embedded_in :address
end
