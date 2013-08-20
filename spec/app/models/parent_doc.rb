class ParentDoc
  include Mongoid::Document
  field :statistic
  field :children_order, type: Array, default: [] # hold all the children's id
  embeds_many :children, class_name: 'ChildDoc', inverse_of: :parent_doc
end
