class Building
  include Mongoid::Document
  embeds_one :building_address
  embeds_many :contractors
end
