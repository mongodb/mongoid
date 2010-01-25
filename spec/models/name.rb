class Name
  include Mongoid::Document
  field :first_name
  field :last_name
  field :parent_title
  key :first_name, :last_name
  has_many :translations
  belongs_to :person, :inverse_of => :name

  def set_parent=(set = false)
    self.parent_title = person.title if set
  end
end