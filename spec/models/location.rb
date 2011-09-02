class Location
  include Mongoid::Document
  field :name
  field :info, :type => Hash
  embedded_in :address
end
