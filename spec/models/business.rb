class Business
  include Mongoid::Document

  set_database :secondary

  field :name
end
