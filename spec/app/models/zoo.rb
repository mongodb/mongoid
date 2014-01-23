class Zoo
  include Mongoid::Document

  has_many :felines
end

class Keeper
  include Mongoid::Document

  has_many :felines
end

class Feline
  include Mongoid::Document

  belongs_to :zoo
  belongs_to :keeper

  validates :keeper, presence: true, uniqueness: { scope: :zoo }
end
