class Cat
  include Mongoid::Document

  field :name

  belongs_to :person

end
