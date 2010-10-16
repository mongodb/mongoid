class Role
  include Mongoid::Document
  field :name, :type => String
  embedded_in :role
  embeds_many :roles
end
