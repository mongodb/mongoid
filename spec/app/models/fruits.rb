module Fruits
  class Apple
    include Mongoid::Document
    has_many :bananas, class_name: "Fruits::Banana"
    recursively_embeds_many
  end

  class Banana
    include Mongoid::Document
    belongs_to :apple, class_name: "Fruits::Apple"
  end

  class Pineapple
    include Mongoid::Document
    recursively_embeds_many cascade_callbacks: true
  end

  class Mango
    include Mongoid::Document
    recursively_embeds_one cascade_callbacks: true
  end

  module Big
    class Ananas
      include Mongoid::Document
    end
  end
end
