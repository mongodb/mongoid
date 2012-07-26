class Name
  include Mongoid::Document

  field :_id, type: String, default: ->{
    "#{first_name}-#{last_name}"
  }

  field :first_name, type: String
  field :last_name, type: String
  field :parent_title, type: String

  embeds_many :translations, validate: false
  embeds_one :language, as: :translatable, validate: false
  embedded_in :namable, polymorphic: true

  accepts_nested_attributes_for :language

  attr_protected :_id, :id

  def set_parent=(set = false)
    self.parent_title = namable.title if set
  end
end
