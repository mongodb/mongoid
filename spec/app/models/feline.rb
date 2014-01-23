class Feline
  include Mongoid::Document

  belongs_to :zoo
  belongs_to :keeper

  validates :keeper, presence: true, uniqueness: { scope: :zoo }
end
