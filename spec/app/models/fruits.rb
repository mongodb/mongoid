module Fruits
  class Apple
    include Mongoid::Document
    has_many :bananas, class_name: "Fruits::Banana"
    has_many :fruits_melons, class_name: "Fruits::Melon"
    recursively_embeds_many
  end

  class Banana
    include Mongoid::Document
    belongs_to :apple, class_name: "Fruits::Apple"
  end

  class Melon
    include Mongoid::Document
    belongs_to :fruit_apple, class_name: "Fruits::Apple"
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
