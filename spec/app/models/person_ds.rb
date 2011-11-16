class PersonDs

  include Mongoid::Document
  embeds_many :addresses, :as => :addressable
  default_scope without(:addresses)

end
