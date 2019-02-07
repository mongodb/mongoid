class EomParent
  include Mongoid::Document

  embeds_one :child, class_name: 'EomChild'

  field :name, type: String
end

class EomChild
  include Mongoid::Document

  embedded_in :parent, class_name: 'EomParent'

  field :a, type: Integer, default: 0
  field :b, type: Integer, default: 0
end
