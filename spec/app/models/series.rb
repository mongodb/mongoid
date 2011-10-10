class Series
  include Mongoid::Document
  has_many :books
end
