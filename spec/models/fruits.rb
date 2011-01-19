module Fruits
  class Apple
    include Mongoid::Document
    references_many :bananas, :class_name => "Fruits::Banana"
  end

  class Banana
    include Mongoid::Document
    referenced_in :apple, :class_name => "Fruits::Apple"
  end
end
