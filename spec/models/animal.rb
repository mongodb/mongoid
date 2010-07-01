class Animal
  include Mongoid::Document
  field :name
  field :tags, :type => Array  
  key :name
  embedded_in :person, :inverse_of => :pet
  
  def tag_list
    tags.join(", ")
  end
  
  def tag_list=(_tag_list)
    self.tags = _tag_list.split(",").map(&:strip)
  end  
end
