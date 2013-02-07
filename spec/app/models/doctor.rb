class Doctor < Person
  field :specialty, as: :spec
  has_and_belongs_to_many :users, validate: false, inverse_of: nil

  def specialty=(text)
    users.push(User.new)
    super
  end
end

class Doktor < Person
end
