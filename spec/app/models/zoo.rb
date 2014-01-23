class Zoo
  include Mongoid::Document

  has_many :felines
end
