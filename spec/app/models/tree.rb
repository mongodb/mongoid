class Tree
  include Mongoid::Document

  field :name
  field :evergreen, type: Mongoid::Boolean

  scope :verdant, ->{ where(evergreen: true) }
  default_scope ->{ asc(:name) }
end
