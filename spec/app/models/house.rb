class House
  include Mongoid::Document
  field :name, :type => String
  field :model, :type => String
  attr_accessible :name, :as => [ :default, :admin ]
end
