class Name
  include Mongoid::Document
  field :first_name
  field :last_name
  field :parent_title
  key :first_name, :last_name
  embed_many :translations
  embedded_in :person, :inverse_of => :name

  def set_parent=(set = false)
    self.parent_title = person.title if set
  end
end
