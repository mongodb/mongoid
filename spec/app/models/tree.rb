class Tree
  include Mongoid::Document

  field :name
  field :evergreen, type: Boolean

  scope :verdant, where(evergreen: true)
  default_scope asc(:name)
end
