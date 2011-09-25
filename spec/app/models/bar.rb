class Bar
  include Mongoid::Document
  field :name, :type => String
  field :location, :type => Array
  has_one :rating, :as => :ratable
  index [[ :location, Mongo::GEO2D ]]
end
