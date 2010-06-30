class ParentDoc
  include Mongoid::Document

  embeds_many :child_docs

  field :statistic
  field :children_order, :type => Array, :default => [] # hold all the children's id
end


class ChildDoc
  include Mongoid::Document

  embedded_in :parent_doc, :inverse_of => :child_docs

  attr_writer :position

  after_save :update_position

  def position
    exsited_position = parent_doc.children_order.index(id)
    exsited_position ? exsited_position + 1 : parent_doc.aspects.size
  end

  def update_position
    if @position && (@position.to_i > 0)
      parent_doc.children_order.delete(id)
      parent_doc.children_order.insert(@position.to_i - 1, id)
      parent_doc.save
    end
  end
end
