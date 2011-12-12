module Trees
  class Node
    include Mongoid::Document
    recursively_embeds_many

    field :name, :type => String

    def is_root?
      parent_node.nil?
    end
  end
end
