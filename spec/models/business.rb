class Business
  include Mongoid::Document
  set_database :secondary
  field :name, :type => String
  has_and_belongs_to_many :owners, :class_name => "User", :validate => false
end
