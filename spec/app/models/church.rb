class Church
  include Mongoid::Document
  has_many :acolytes, validate: false
end
