class Circus
  include Mongoid::Document

  field :name

  embeds_many :animals
end
