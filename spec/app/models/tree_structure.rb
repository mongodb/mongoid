class TreeStructure
  include Mongoid::Document

  belongs_to :parent,   :class_name => "TreeStructure", :inverse_of => :children
  has_many   :children, :class_name => "TreeStructure", :inverse_of => :parent
end
