class ParentDoc
  include Mongoid::Document
  field :statistic
  field :children_order, type: Array, default: [] # hold all the children's id
  embeds_many :child_docs
end
