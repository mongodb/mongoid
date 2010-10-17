class Role
  include Mongoid::Document
  field :name, :type => String
  embedded_in :parent_role, :class_name => "Role", :cyclic => true
  embeds_many :child_roles, :class_name => "Role", :cyclic => true
end
