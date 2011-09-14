class Animal
  include Mongoid::Document
  field :name
  field :height, :type => Integer
  field :weight, :type => Integer
  field :tags, :type => Array
  key :name

  embedded_in :person
  embedded_in :circus

  validates_format_of :name, :without => /\$\$\$/

  accepts_nested_attributes_for :person

  def tag_list
    tags.join(", ")
  end

  def tag_list=(_tag_list)
    self.tags = _tag_list.split(",").map(&:strip)
  end
end
