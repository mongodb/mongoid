class Zoo
  include Mongoid::Document

  field :name, :type => String

  has_one :mammal
  embeds_one :reptile

  has_many :mammals
  embeds_many :reptiles

  accepts_nested_attributes_for :mammal, :reptile
  accepts_nested_attributes_for :mammals, :reptiles
end

class Mammal
  include Mongoid::Document
  belongs_to :zoo
  field :name, :type => String
end

class Moose < Mammal
  field :antlers, :type => Integer
end

class Cheetah < Mammal
  field :speed, :type => BigDecimal
end

class Reptile
  include Mongoid::Document
  embedded_in :zoo
  field :name, :type => String
end

class Snake < Reptile
  field :length, :type => Integer
end

class FrilledLizard < Reptile
  field :color, :type => String
end