class Doctor < Person
  field :specialty
  has_and_belongs_to_many :users, :validate => false, :inverse_of => nil

  def specialty=(text)
    users.push(User.new)
    super
  end
end
