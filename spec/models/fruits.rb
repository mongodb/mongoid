module Fruits
  class Apple
    include Mongoid::Document
    has_many :bananas, :class_name => "Fruits::Banana"
  end

  class Banana
    include Mongoid::Document
    belongs_to :apple, :class_name => "Fruits::Apple"
  end
end
