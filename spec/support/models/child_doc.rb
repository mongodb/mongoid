# frozen_string_literal: true

class ChildDoc
  include Mongoid::Document

  embedded_in :parent_doc

  attr_writer :position

  after_save :update_position

  def position
    existing_position = parent_doc.children_order.index(id)
    existing_position ? existing_position + 1 : parent_doc.aspects.size
  end

  def update_position
    if @position && (@position.to_i > 0)
      parent_doc.children_order.delete(id)
      parent_doc.children_order.insert(@position.to_i - 1, id)
      parent_doc.save!
    end
  end
end
