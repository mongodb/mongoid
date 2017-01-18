class Sandwich
  include Mongoid::Document
  has_and_belongs_to_many :meats

  field :name, type: String

  belongs_to :posteable, polymorphic: true
  accepts_nested_attributes_for :posteable, autosave: true
end
