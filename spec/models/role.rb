class Role
  include Mongoid::Document
  field :name, :type => String
  recursively_embeds_many
end
