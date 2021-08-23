# frozen_string_literal: true

class Name
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :_id, type: String, overwrite: true, default: ->{
    "#{first_name}-#{last_name}"
  }

  field :first_name, type: String
  field :last_name, type: String
  field :parent_title, type: String
  field :middle, type: String

  embeds_many :translations, validate: false
  embeds_one :language, as: :translatable, validate: false
  embedded_in :namable, polymorphic: true
  embedded_in :person

  accepts_nested_attributes_for :language

  def set_parent=(set = false)
    self.parent_title = namable.title if set
  end
end
