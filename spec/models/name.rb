class Name
  include Mongoid::Document
  field :first_name
  field :last_name
  field :parent_title
  key :first_name, :last_name
  embeds_many :translations
  embedded_in :namable, :inverse_of => [:name, :names]

  def set_parent=(set = false)
    self.parent_title = namable.title if set
  end
end
