class Exhibition
  include Mongoid::Document
  has_many :exhibitors
end
