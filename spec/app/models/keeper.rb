class Keeper
  include Mongoid::Document

  has_many :felines
end
