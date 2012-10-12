class Building
  include Mongoid::Document
  attr_accessible
  attr_accessible :building_address, :contractors, as: :admin
  embeds_one :building_address
  embeds_many :contractors
end
